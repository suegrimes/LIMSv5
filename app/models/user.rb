# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  login                     :string(25)
#  email                     :string(255)
#  crypted_password          :string(40)
#  salt                      :string(40)
#  reset_code                :string(50)
#  created_at                :datetime
#  updated_at                :datetime
#  remember_token            :string(255)
#  remember_token_expires_at :datetime
#

require 'digest/sha1'
class User < ApplicationRecord
  #using_access_control
  
  # ---------------------------------------
  # The following code has been generated by role_requirement.
  # You may wish to modify it to suit your need
  has_and_belongs_to_many :roles
  has_one :researcher
  
  # Class virtual attribute for current_user (set in application controller)
  cattr_accessor :current_user
  # Instance virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password
  before_create :set_as_active
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  # this is no longer supported in rails 4 or 5
  #attr_accessible :login, :email, :password, :password_confirmation, :roles, :role_ids

  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question, admin='admin_defaults_to_true')
    @_list ||= self.roles.collect(&:name)
    return true if (@_list.include?("admin") && admin == 'admin_defaults_to_true')
    (@_list.include?(role_in_question.to_s) )
  end
  # ---------------------------------------
  
  # This method needed for declarative_authorization gem
  def role_symbols
    (roles || []).map {|r| r.name.to_sym}
  end
  
  # Returns only users which current role is authorized to see
  # All users may see their own record;
  # Clin_admin can additionally see all users with role = clinical, or clin_admin
  # Admin can see all users
  def self.find_all_with_authorization(user=current_user)
    if user.has_role?("admin") && !DEMO_APP
      users = self.includes(:roles).order(:active_inactive, :lab_name).all
    else
      users = self.includes(:roles).where("users.login = ?", user.login).all
    end
    return users
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(:validate=>false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate=>false)
  end
  
  def create_reset_code
    @reset = true
    self.reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    save(:validate=>false)
  end
  
  def recently_reset?
    @reset
  end
  
  def delete_reset_code
    self.reset_code = nil
    save(:validate=>false)
  end

  def set_as_active
    active_inactive = 'A'
  end
  
  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
      
    def password_required?
      crypted_password.blank? || !password.blank?
    end
       
end

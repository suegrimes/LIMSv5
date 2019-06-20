class WelcomeController < ApplicationController
  layout 'auth'
  skip_before_action :login_required
  skip_before_action :log_user_action

  if DEMO_APP
    include SslRequirement 
    ssl_required :xxx_index, :user_login, :signup, :add_user
  end
  
  def index
    if logged_in?
      render 'index', layout: 'main/main'
    else
      render 'login'
    end
  end

  def user_login
    # in case someone navigates here while already logged in
    if logged_in?
      flash[:notice] = "Already logged in as #{self.current_user.login} - Logout to change user"
      redirect_to :root
      return
    end
    #self.current_user = User.authenticate(params[:login], params[:password])
    # using bootstrap_forms_for(@user) puts user params inside a user hash
    user_params = params[:user]
    if user_params
      self.current_user = User.authenticate(user_params[:login], user_params[:password])
    else
      raise "Missing user parameters"
    end
    # Authorization::current_user = @user   # for declarative_authorization #
    if logged_in?
      log_entry("Login")
      if user_params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      #flash[:notice] = "Login successful"
      redirect_to :root
    else
      @invalid_login_flag = 1;
      flash.now[:error] = "Invalid login - please try again"
      render :action => 'login'
    end
  end

  def signup
    @user = User.new()
  end
  
  def add_user
    @user = User.new(user_params_allowed)

    default_role = Role.find_by_name(Role::DEFAULT_ROLE) if Role::DEFAULT_ROLE
    @user.roles << Role.where('id = ?', default_role.id).all if default_role
    @user.save!

    self.current_user = @user
    log_entry("Login")
    flash[:notice] = "Thanks for signing up!"
    redirect_to :root

    rescue ActiveRecord::RecordInvalid
      render :action => 'signup'
  end
  
  def logout
    log_entry("Logout")
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash.now[:notice] = "You have been logged out."
    render :action => 'login'
  end
  
protected
  def log_entry(user_action)
    logger.info("<**#{user_action}**> User: " + current_user.login + " IP: " + request.remote_ip +
                                    " Date/Time: " + Time.now.strftime("%Y-%m-%d %H:%M:%S"))
    UserLog.add_entry(self, current_user, request.remote_ip)
  end  

  def user_params_allowed
    params.require(:user).permit(:login, :email, :password, :password_confirmation)
  end
end

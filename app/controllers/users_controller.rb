
class UsersController < ApplicationController
  layout 'auth'
  ## cancan
  #load_and_authorize_resource
  
  ## declarative_authorization ##
  #filter_access_to [:new, :create, :index]
  #filter_access_to [:edit, :update, :show], :attribute_check => true
  
  ## role_authorization ##
  skip_before_action :login_required, :only => [:new, :create, :forgot, :reset]
  #require_role "admin", :for_all_except => [:new, :create]
  if DEMO_APP
    include SslRequirement   
    ssl_required :xxx_index, :new, :create, :edit, :update, :destroy, :reset
  end

  # render index.rhtml
  def index
    if current_user.has_role?("admin")
      users = User.find_all_with_authorization
      @users = users.group_by {|user| user.active_inactive}
      render :action => 'index'
    else
      @user = current_user
      render :action => 'show'
    end
  end

  # GET /users/1
  def show
    @user = User.find(params[:id])
    @user = current_user if (cannot? :read, @user)
  end

  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(create_params_allowed)
    
    if @user.errors.empty?
      default_role = Role.find_by_name(Role::DEFAULT_ROLE) if Role::DEFAULT_ROLE
      @user.roles << Role.where('id = ?', default_role.id).all if default_role
      @user.save
      self.current_user = @user
      
      #Authorization::current_user = @user   # for declarative_authorization #
      redirect_to root_url
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end
  
  # render edit.html
  def edit 
    @user = User.find(params[:id])
    @user = current_user if (cannot? :edit, @user)
    @roles = Role.all

    if DEMO_APP && current_user.login != @user.login
      render :action => 'show'
    else
      render :action => 'edit'
    end
  end
  
  def update
    @user = User.find(params[:id])
    authorize! :update, @user
    
    if can? :edit, Role
      params[:user][:role_ids] ||= []
      #@user.roles = Role.find(params[:user][:role_ids])
    end
    
    if DEMO_APP && DEMO_USERS.include?(@user.login)
      flash.now[:error] = "Change functionality disabled for default user logins in demo application"
      @roles = Role.all
      render :action => 'edit'
      
    elsif current_user.has_role?("admin") || @user.authenticated?(params[:curr_user][:current_password])
      if @user.update_attributes(update_params_allowed)
        flash[:notice] = "User has been updated"
        redirect_to users_url
      else
        flash.now[:error] = "Error updating user"
        @roles = Role.all
        render :action => 'edit'
      end
      
    else
      flash.now[:error] = "Incorrect current password entered - please try again"
      @roles = Role.all
      render :action => 'edit'
    end
  end
  
  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    if DEMO_APP && DEMO_USERS.include?(@user.login)
      flash[:error] = "Delete functionality disabled for default user logins in demo application"
      redirect_to users_url
      
    else
      authorize! :destroy, @user      
      @user.destroy
      redirect_to(users_url) 
    end
  end
  
  def forgot
    if request.post?
      user = User.find_by_email(params[:user][:email])
      if user
        user.create_reset_code
        flash[:notice] = "Reset code sent to #{user.email}"
      else
        flash[:notice] = "#{params[:user][:email]} does not exist in system"
      end
    render :action => :display_message
    end
  end
  
  def reset
    @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
    if request.post?
      if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
        self.current_user = @user
        @user.delete_reset_code
        flash[:notice] = "Password reset successfully for #{@user.email} - You are now logged in"
        redirect_to :controller => :welcome, :action => :index
      else
        render :action => :reset
      end
    end
  end

  private

  def create_params_allowed
    params.require(:user).permit(:login, :email, :password, :password_confirmation)
  end
    
  def update_params_allowed
    # mhayden: note that simply listing :role_id does not work since it is on an association
    # needs to be role_ids: []
    params.require(:user).permit(:login, :email, :password, :password_confirmation, role_ids: [])
  end
    
end


class SessionsController < ApplicationController
  before_filter :signed_in_user, :only => [:index]
  def index
    @mobile_sessions = MobileSession.all(:conditions => ['user_id = ? AND mobile_auth_token IS NOT NULL', current_user.id])
  end

  def new
  end

  def create
  	user = User.find_by_email(params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      sign_in user
      redirect_back_or user
    else
      flash.now[:error] = 'Invalid email/password combination' # Not quite right!
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end
end

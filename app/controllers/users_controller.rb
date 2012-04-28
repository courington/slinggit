class UsersController < ApplicationController
  before_filter :signed_in_user, only: [:edit, :update]
  before_filter :correct_user, only: [:edit, :update]
  before_filter :admin_user, only: [:index, :destroy]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    #user has chosen to twitter authenticate --
    #verify name and email are present and not taken
    if not params[:twitter_authenticate].blank?
      if params[:user][:name].blank?
        @user.errors.messages[:name] = ["can't be blank"]
      end
      if params[:user][:email].blank?
        @user.errors.messages[:email] = ["can't be blank"]
      else
        if User.exists?(:email => params[:user][:email])
          @user.errors.messages[:email] = ["has already been registered"]
        end
      end

      if @user.errors.blank?
        session[:twitter_user] = @user
        #redirect_to_twitter
      else
        render 'new'
      end
    else
      if @user.save
        sign_in @user
        flash[:success] = "Welcome SlingGit.  Time to start slingin!"
        redirect_to @user
      else
        render 'new'
      end
    end
  end

  def edit
    # @user = User.find(params[:id]) !Not needed because of :correct_user before_filter
    @twitterclient = client if @user.twitter_authorized?
  end

  def update
    # @user = User.find(params[:id])  !Not needed because of :correct_user before_filter
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated"
      sign_in @user
      reset_session
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed."
    redirect_to users_path
  end

  private

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_path) unless current_user?(@user)
  end

  def admin_user
    redirect_to(root_path) unless current_user.admin?
  end

end

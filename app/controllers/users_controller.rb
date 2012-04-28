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
    #if not params[:twitter_authenticate].blank?
    #
    #end
    if @user.save
      sign_in @user
      flash[:success] = "Welcome SlingGit.  Time to start slingin!"
      redirect_to @user
    else
      render 'new'
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

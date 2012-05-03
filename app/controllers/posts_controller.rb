class PostsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :destroy, :edit, :new]
  before_filter :correct_user, only: [:destroy, :edit, :update]
  before_filter :load_api_accounts, :only => [:new, :create]

  def index
  end

  def show
    @post = Post.find(params[:id])
    @comments = @post.comments.paginate(page: params[:page])
    # Since we give an non-singed in user the option to sign in, we
    # want to return them to the post after signin.
    unless signed_in?
        store_location
    end    
  end

  def new
    if signed_in?
      @post = Post.new
    end
  end

  def create
    @post = current_user.posts.build(params[:post])
    if not params[:twitter_accounts].blank?
      #TODO rework this into the form
      @post.recipient_api_account_ids = params[:twitter_accounts].map { |x| x.first }.join(',')
    end
    if @post.save
      @post.do_post
      flash[:success] = "Post successfully created!"
      redirect_to current_user
    else
      render 'new'
    end
  end

  def edit
    # Don't need to find Post here because of correct_user filter
    store_location if !@post.open?
  end

  def update
    # Don't need to find Post here because of correct_user filter
    if @post.update_attributes(params[:post])
      flash[:success] = "Prost updated"
      redirect_back_or current_user
    else
      render 'edit'
    end
  end

  def destroy
    @post.destroy
    redirect_back_or current_user
  end

  private

  def correct_user
    @post = current_user.posts.find_by_id(params[:id])
    redirect_to current_user if @post.nil?
  end

  def load_api_accounts
    @twitter_accounts = ApiAccount.all(:conditions => ['user_id = ? AND api_source = ?', current_user.id, 'twitter'])
  end
end
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
    posts_to_perform = []
    if not params[:twitter_accounts].blank?
      twitter_accounts = params[:twitter_accounts]
      params.delete(:twitter_accounts)
      twitter_accounts.each do |id, value|
        @post = current_user.posts.build(params[:post].merge!(:last_result => 'no_attempt'))
        @post.host_machine = request.env['HTTP_HOST']
        @post.api_account_id = id.to_i
        @post.open = true;
        @post.status = 'active'
        if not @post.save
          render 'new'
          return
        else
          posts_to_perform << @post
        end
      end
    end

    posts_to_perform.each do |post|
      post.do_post
    end

    flash[:success] = "Post(s) successfully created!"
    redirect_to current_user
  end

  def edit
    # Don't need to find Post here because of correct_user filter
  end

  def update
    # Don't need to find Post here because of correct_user filter
    if @post.update_attributes(params[:post])
      flash[:success] = "Prost updated"
      redirect_to current_user
    else
      render 'edit'
    end
  end

  def destroy
    @post.status = 'deleted'
    @post.save
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
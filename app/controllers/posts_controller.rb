class PostsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :destroy, :edit, :new]
  before_filter :correct_user, only: [:destroy, :edit, :update]
  before_filter :load_api_accounts, :only => [:new, :create]

  def index
  end

  def show
    @post = Post.find(params[:id])
    # creating user object to compare against current_user
    # in order to display edit option.  Dan, if there's a
    # better way, fell free to change this.
    @user = User.find(@post.user_id)
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
    recipient_api_account_ids = []
    twitter_accounts = params[:twitter_accounts]
    params.delete(:twitter_accounts)

    @post = current_user.posts.build(params[:post])
    if not @post.save
      render 'new'
      return
    else
      if not twitter_accounts.blank?
        twitter_accounts.each do |id, value|
          recipient_api_account_ids << id
          TwitterPost.create(
              :user_id => @post.user_id,
              :api_account_id => id.to_i,
              :post_id => @post.id,
              :content => @post.content
          ).do_post
        end

        if not recipient_api_account_ids.blank?
          @post.update_attribute(:recipient_api_account_ids, recipient_api_account_ids.join(','))
        end
      end

      flash[:success] = "Post successfully created!"
      redirect_to current_user
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

  def list
    if not params[:search_term].blank?
      #this needs refactored for pagination
      @posts = Post.all(:conditions => ["content like ? OR hashtag_prefix like ?", params[:search_term]])
    end
  end

end
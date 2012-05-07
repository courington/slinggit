class PostsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :destroy, :edit, :new]
  before_filter :correct_user, only: [:destroy, :edit, :update]
  before_filter :load_api_accounts, :only => [:new, :create]

  def index
  end

  def show
    @post = Post.first(:conditions => ['id = ?', params[:id]])
    if not @post.blank?
      @comments = @post.comments.paginate(page: params[:page])
      # creating user object to compare against current_user
      # in order to display edit option.  Dan, if there's a
      # better way, fell free to change this.
      @user = User.find(@post.user_id)
      # Since we give an non-singed in user the option to sign in, we
      # want to return them to the post after signin.
      unless signed_in?
        store_location
      end
    else
      flash[:error] = 'Oops, we were unable to find the post you were looking for.'
      redirect_to :controller => 'static_pages', :action => 'home'
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

  def results
    if not params[:id].blank?
      @posts = Post.all(:conditions => ["content like ? OR hashtag_prefix like ? OR location like ?", "%#{params[:id]}%", "%#{params[:id]}%", "%#{params[:id]}%"], :order => 'created_at desc')
    end
  end

  private

  def correct_user
    if signed_in?
      @post = Post.first(:conditions => ['user_id = ? AND id = ?', current_user.id, params[:id]])
      if @post.blank?
        redirect_to current_user
      end
    else
      redirect_to new_user_path
    end
  end

  def load_api_accounts
    @twitter_accounts = ApiAccount.all(:conditions => ['user_id = ? AND api_source = ?', current_user.id, 'twitter'])
  end

end
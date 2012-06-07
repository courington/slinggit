class PostsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :destroy, :edit, :new]
  before_filter :correct_user, only: [:destroy, :edit, :update]
  before_filter :load_api_accounts, :only => [:new, :create]
  # CMK: I'm not sure I was asking Dan the right questions tonight about
  # where to put this, but this seems cleaner than putting it the model.
  before_filter :get_id_for_slinggit_api_account, :only => [:new, :create]

  def index
  end

  def show
    @post = Post.first(:conditions => ['id = ?', params[:id]])
    if not @post.blank? and not @post.is_deleted?
      @comments = @post.comments.paginate(page: params[:page])
      # creating user object to compare against current_user
      # in order to display edit option.  Dan, if there's a
      # better way, fell free to change this.
      @user = User.find(@post.user_id)
      @api_account = @user.primary_twitter_account
      if not @api_account.blank?
        @twitter_post = TwitterPost.first(conditions: ['post_id = ? AND api_account_id = ? ', @post.id, @api_account.id])
      end
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
    @post = Post.new
    success = passes_limitations?(:posts)
    if not success
      @cant_post = true
      flash[:notice] = 'In order to keep postings on Slinggit relevant, we currently only allow 10 posts every 24 hours.  Please wait a while and post again.'
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
          # We need to first make sure the user is the owner of this account, or that
          # it is the slinggit account. Should we log a volation here?
          proposed_api_account = ApiAccount.first(:conditions => ['id = ?', id], :select => 'user_id')
          if not proposed_api_account.blank?
            if current_user.id == proposed_api_account.user_id || proposed_api_account.user_id == 0
              recipient_api_account_ids << id
              TwitterPost.create(
                  :user_id => @post.user_id,
                  :api_account_id => id.to_i,
                  :post_id => @post.id,
                  :content => @post.content
              ).do_post
            end
          end  
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
    # For now, we're only allowing the user to update open/close status
    if @post.update_attributes(params[:post])
      flash[:success] = "Post updated"
      redirect_back_or post_path(@path)
    else
      render 'edit'
    end
  end

  # def destroy
  #   @post.status = 'deleted'
  #   @post.save
  #   redirect_back_or current_user
  # end

  def results
    if not params[:id].blank?
      #I am currently researching how to make this function more like google search.  Faster and more relevent.
      @searchTerm = params[:id]
      @posts = Post.all(:conditions => ["(content like ? OR hashtag_prefix like ? OR location like ?) AND open = ? AND status = ?", "%#{params[:id]}%", "%#{params[:id]}%", "%#{params[:id]}%", true, STATUS_ACTIVE], :order => 'created_at desc')
    end
  end

  private

  def correct_user
    if signed_in?
      @post = Post.first(:conditions => ['user_id = ? AND id = ? AND status = ?', current_user.id, params[:id], STATUS_ACTIVE])
      if @post.blank?
        redirect_to current_user
      end
    else
      redirect_to new_user_path
    end
  end

  def load_api_accounts
    @twitter_accounts = ApiAccount.all(:conditions => ['user_id = ? AND api_source = ? AND status != ?', current_user.id, 'twitter', STATUS_DELETED])
  end

  def get_id_for_slinggit_api_account
    slinggit_api_account = ApiAccount.first(:conditions => ['user_id = ? AND user_name = ?', 0, Rails.configuration.slinggit_username], :select => 'id')
    @slinggit_account_id = slinggit_api_account.id
  end

end
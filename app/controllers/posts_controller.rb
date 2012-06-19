class PostsController < ApplicationController
  before_filter :user_verified, only: [:create, :destroy, :eidt, :new]
  before_filter :signed_in_user, only: [:create, :destroy, :edit, :new]
  before_filter :non_suspended_user, only: [:new]
  before_filter :correct_user, only: [:destroy, :edit, :update]
  before_filter :load_api_accounts, :only => [:new, :create]
  before_filter :get_id_for_slinggit_api_account, :only => [:new, :create]

  def index
    @posts = Post.paginate(page: params[:page], :per_page => 10, :conditions => ['open = ? AND status != ?', true, STATUS_DELETED], :order => 'id desc')
  end

  def show
    @post = Post.first(:conditions => ['id = ?', params[:id]])
    if not @post.blank? and not @post.is_deleted?
      @comments = @post.comments.paginate(page: params[:page], :conditions => ['status = ?', STATUS_ACTIVE])
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
    selected_networks = params[:selected_networks]
    params.delete(:selected_networks)

    @post = current_user.posts.build(params[:post])
    if not @post.save
      render 'new'
      return
    else
      if not selected_networks.blank?
        selected_networks.each do |id, value|
          # We need to first make sure the user is the owner of this account, or that
          # it is the slinggit account. Should we log a volation here?
          if proposed_api_account = ApiAccount.first(:conditions => ['id = ?', id], :select => 'user_id,api_source')
            if current_user.id == proposed_api_account.user_id || proposed_api_account.user_id == 0
              recipient_api_account_ids << id
              if proposed_api_account.api_source == 'twitter'
                TwitterPost.create(
                    :user_id => @post.user_id,
                    :api_account_id => id.to_i,
                    :post_id => @post.id,
                    :content => @post.content
                ).do_post
              elsif proposed_api_account.api_source == 'facebook'
                FacebookPost.create(
                    :user_id => @post.user_id,
                    :api_account_id => id.to_i,
                    :post_id => @post.id,
                    :message => "For sale: ##{@post.hashtag_prefix}",
                    :name => "$#{@post.price}.00",
                    :caption => "Location: #{@post.location}",
                    :description => @post.content,
                    :image_url => @post.has_photo? ? "#{BASEURL}#{@post.root_url_path}" : nil,
                    :link_url => nil #if this is nil it will default to the post
                ).do_post
              end
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

  def delete_post
    post = Post.first(:conditions => ['id = ?', params[:id]])
    if not post.blank? and post.user_id == current_user.id
      if post.update_attribute(:status, STATUS_DELETED)
        flash[:success] = "Post #{post.hashtag_prefix} successfully removed."
        redirect_to user_path(current_user)
      end
    end
  end

  # def destroy
  #   @post.status = 'deleted'
  #   @post.save
  #   redirect_back_or current_user
  # end

  def results
    #rework this again later
    search_terms = []
    @posts = []
    if not params[:id].blank?
      search_terms = params[:id].split(' ')
      if search_terms.length > 1
        @posts = Post.all(:conditions => ["(content in (?) OR hashtag_prefix in (?) OR location in (?)) AND open = ? AND status = ?", search_terms, search_terms, search_terms, true, STATUS_ACTIVE], :order => 'created_at desc')
        if @posts.length == 0
          search_terms = [search_terms[0], search_terms[1], search_terms[2]] #limit to 3 search terms
          search_terms.each do |search_term|
            search_term = search_term.strip[1, search_term.length - 1]
            @posts | Post.all(:conditions => ["(content like ? OR hashtag_prefix like ? OR location like ?) AND open = ? AND status = ?", "%#{search_terms}%", "%#{search_terms}%", "%#{search_terms}%", true, STATUS_ACTIVE], :order => 'created_at desc')
          end
        end
      elsif search_terms.length == 1
        @posts = Post.all(:conditions => ["(content like ? OR hashtag_prefix like ? OR location like ?) AND open = ? AND status = ?", "%#{search_terms[0]}%", "%#{search_terms[0]}%", "%#{search_terms[0]}%", true, STATUS_ACTIVE], :order => 'created_at desc')
        if @posts.length == 0
          search_term = search_terms[0].strip[1,search_terms.length - 1]
          @posts = Post.all(:conditions => ["(content like ? OR hashtag_prefix like ? OR location like ?) AND open = ? AND status = ?", search_term, search_term, search_term, true, STATUS_ACTIVE], :order => 'created_at desc')
        end
      end
    else
      flash[:error] = "Oops... it would appear that I had nothing to search for.  Here is a list of items sorted by most recent."
      redirect_to :controller => :posts, :action => :index
    end
  end

  def report_abuse
    if not params[:id].blank?
      if post = Post.first(:conditions => ['id_hash = ?', params[:id]])
        FlaggedContent.create(
            :creator_user_id => signed_in? ? current_user.id : nil,
            :source => 'post',
            :source_id => post.id
        )
        flash[:success] = "Post has been flagged and will be reviewed as soon as possible."
      end
    end

    if not request.referer.blank?
      redirect_to request.referer
    else
      redirect_to post_path
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
    @facebook_accounts = ApiAccount.all(:conditions => ['user_id = ? AND api_source = ? AND status != ?', current_user.id, 'facebook', STATUS_DELETED])
  end

  def get_id_for_slinggit_api_account
    slinggit_api_account = ApiAccount.first(:conditions => ['user_id = ? AND user_name = ?', 0, Rails.configuration.slinggit_username], :select => 'id')
    @slinggit_account_id = slinggit_api_account.id
  end

end
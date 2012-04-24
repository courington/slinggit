class PostsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :destroy, :edit]
  before_filter :correct_user,   only: [:destroy, :edit, :update]

  def index
  end

  def show
  	@post = Post.find(params[:id])
  end	

  def new
    if signed_in?
  	  @post = current_user.posts.build 
      @twitterclient = client if current_user.twitter_authorized?
    end  
  end

  def create
    @post = current_user.posts.build(params[:post])
    if @post.save
      # I'm pretty sure this will need to be reworked with some rescue methods.
      if current_user.twitter_authorized?
        @twitterclient = client
        @twitterclient.update("##{@post.hashtag_prefix}forsale #{@post.content} - #{@post.price} | #{Rails.root}#{post_path(@post)}")
        @slinggitclient = slinggit_client
        @slinggitclient.retweet(@twitterclient.user_timeline.first.id)
      end
      flash[:success] = "Post successfully created!"
      redirect_to current_user
    else
      render 'new'
    end
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
    @post.destroy
    redirect_back_or current_user
  end

  private

    def correct_user
      @post = current_user.posts.find_by_id(params[:id])
      redirect_to current_user if @post.nil?
    end
end
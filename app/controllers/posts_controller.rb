class PostsController < ApplicationController
  before_filter :signed_in_user, only: [:create, :destroy, :edit]
  before_filter :correct_user,   only: [:destroy, :edit, :update]

  def index
  end

  def show
  	@post = Post.find(params[:id])
  end	

  def new
  	@post = current_user.posts.build if signed_in?
  end

  def create
    @post = current_user.posts.build(params[:post])
    if @post.save
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
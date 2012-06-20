class CommentsController < ApplicationController

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.new(params[:comment])
    if not @comment.save
      flash[:error] = "Comments can only be 300 characters"
    end
    redirect_to post_path(@post)
  end

  def delete
    if comment = Comment.first(:conditions => ['id_hash = ?', params[:id]], :select => 'id,status,user_id')
      if signed_in? and (current_user.id == comment.user_id or current_user.id == comment.post('user_id').user_id)
        comment.update_attribute(:status, STATUS_DELETED)
        flash[:success] = "Comment deleted"
      end
    end
    if not request.referer.blank?
      redirect_to request.referer
    else
      redirect_to post_path
    end
  end

end

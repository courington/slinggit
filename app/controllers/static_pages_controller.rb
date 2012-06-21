class StaticPagesController < ApplicationController
  before_filter :invite_only_home_redirect, only: [:home]

  def home
    @posts = Post.paginate(page: params[:page], :per_page => 2, :conditions => ['open = ? AND status != ?', true, STATUS_DELETED], :order => 'id desc')
    if signed_in?
      @primary_twitter_account = ApiAccount.first(:conditions => ['user_id = ? AND status = ?', current_user.id, STATUS_PRIMARY])
    end
  end

  def about
  end

  def contact
  end

  def help
  end	

end

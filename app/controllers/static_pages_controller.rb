class StaticPagesController < ApplicationController
  def home
    @posts = Post.find(:first)
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

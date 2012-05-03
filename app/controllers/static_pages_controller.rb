class StaticPagesController < ApplicationController
  def home
    if signed_in?
      @primary_twitter_account = ApiAccount.first(:conditions => ['user_id = ? AND status = "primary"', current_user.id])
    end
  end

  def about
  end
end

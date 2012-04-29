class StaticPagesController < ApplicationController
  def home
    if not current_user.blank?
      debugger
      @twitterclient = client if current_user.twitter_authorized?
      debugger
    end
  end

  def about
  end
end

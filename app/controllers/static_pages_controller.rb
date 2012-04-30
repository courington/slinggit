class StaticPagesController < ApplicationController
  def home
    if not current_user.blank?
      @twitterclient = client if current_user.twitter_authorized?
    end
  end

  def about
  end
end

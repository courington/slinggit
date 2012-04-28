module ApplicationHelper

  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "Slinggit"
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end

  def client
    @client ||= Twitter::Client.new(:oauth_token => current_user.twitter_atoken, :oauth_token_secret => current_user.twitter_asecret)
  end

end


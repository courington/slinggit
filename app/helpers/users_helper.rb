module UsersHelper

  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user)
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "https://gravatar.com/avatar/#{gravatar_id}.png"
    image_tag(gravatar_url, alt: user.name, class: "gravatar", :height => "auto", :width => "100%", :style => "max-width: 80px;")
  end

end

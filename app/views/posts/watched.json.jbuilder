json.posts get_posts_for_user("watched", params[:page], 20, @user.id, STATUS_ACTIVE, true) do |json, post|
	# We'll most likely get a deprication warning, however,
	# This appears to be a bug right now.  It should be:
	# json.partial! post
	json.partial! 'posts/post.json.jbuilder', post: post
end
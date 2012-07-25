json.(@user, :id)

json.posts @user.posts do |json, post|
	json.partial! post
end
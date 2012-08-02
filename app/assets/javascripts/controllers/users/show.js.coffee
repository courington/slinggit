# File: controllers/users/show

## Imports
Slinggit.Collections ||= {}
Slinggit.Views.Posts ||= {}
Slinggit.Models ||= {}

## Module
class Slinggit.Controllers.Users.Show extends Backbone.Router
	initialize: (options)->
		@json = options.json
		@posts = new Slinggit.Collections.Posts()
		@postListView = new Slinggit.Views.Posts.PostListView( collection: @posts )
		@user = new Slinggit.Models.User(id: @json.id)
	routes:
		""   :  "root"
		"watching":  "watchedPosts"
		"archived":  "archivedPosts"

	root: =>
		@posts.reset @json.open_posts
		console.log @user


	watchedPosts: =>
		currentUrl = @posts.url
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=watched"
		@posts.fetch
			success: =>
				# success code
				@posts.url = currentUrl
			error: =>
				# error code

	archivedPosts: =>
		currentUrl = @posts.url
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=archived"
		@posts.fetch
			success: =>
				# success code
				@posts.url = currentUrl
			error: =>
				# error code
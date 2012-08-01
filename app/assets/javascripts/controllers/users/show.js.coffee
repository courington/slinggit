# File: controllers/users/show

## Imports
Slinggit.Collections ||= {}
Slinggit.Views.Posts ||= {}

## Module
class Slinggit.Controllers.Users.Show extends Backbone.Router
	initialize: (options)->
		@json = options.json
		@posts = new Slinggit.Collections.Posts()

	routes:
		""   :  "root"
		"watching":  "watchedPosts"

	root: ->
		postListView = new Slinggit.Views.Posts.PostListView( collection: @posts )
		@posts.reset @json.open_posts

	watchedPosts: ->
		currentUrl = @posts.url
		console.log @posts.url
		@posts.url = "/posts/watched.json"
		console.log @posts.url
		@posts.fetch
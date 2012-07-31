# File: controllers/users/show

## Imports
Slinggit.Collections ||= {}
#Slinggit.Views.Posts ||= {}

## Module
class Slinggit.Controllers.Users.Show extends Backbone.Router
	initialize: (options)->
		@json = options.json
		@posts = new Slinggit.Collections.Posts()
		console.log @json

	routes:
		""   :  "root"

	root: ->
		postListView = new Slinggit.Views.Posts.PostListView( collection: @posts )
		@posts.reset @json.posts
# File: collections/posts

## Module
class Slinggit.Collections.Posts extends Backbone.Collection
	initialize: (options)->
		@model = Slinggit.Models.Post

	url: "/posts"
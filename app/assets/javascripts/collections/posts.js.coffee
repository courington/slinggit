# File: collections/posts

## Imports
Slinggit.Models ||= {}

## Module
class Slinggit.Collections.Posts extends Backbone.Collection
	url: "/posts"
	model: Slinggit.Models.Post

	initialize: (options)->
		@defaultUrl = @url
		console.log @defaultUrl

	restoreDefualtUrl: =>
		@url = @defaultUrl
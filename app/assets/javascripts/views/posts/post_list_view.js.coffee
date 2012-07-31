# File: views/posts/post_list_view

## Imports
Slinggit.Views.Posts ||= {}

## Module
class Slinggit.Views.Posts.PostListView extends Backbone.View
	template: JST["posts/show"]

	el: "#postArticlesWrapper"

	initialize: (options)->
		@collection = options.collection
		@collection.bind 'reset', @addAll, @
		@collection.bind 'fetch', @addAll, @


	addAll: ->
		@$el.empty()
		console.log @collection
		@$el.append(@template(posts: @collection))


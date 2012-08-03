# File: views/posts/post_list_view

## Imports
Slinggit.Views.Posts ||= {}

## Module
class Slinggit.Views.Posts.PostListView extends Backbone.View
	template: JST["posts/show"]

	el: "#postArticles"

	initialize: (options)->
		@collection = options.collection
		@collection.on 'reset', @addAll, @
		@collection.on 'fetch', @addAll, @


	addAll: ->
		@$el.empty()
		@$el.append(@template(posts: @collection))


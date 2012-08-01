# File: views/posts/post_list_view

## Imports
Slinggit.Views.Posts ||= {}

## Module
class Slinggit.Views.Posts.PostListView extends Backbone.View
	template: JST["posts/show"]

	el: "#postArticlesWrapper"

	initialize: (options)->
		@collection = options.collection
		@collection.on 'reset', @addAll, @
		@collection.on 'fetch', @addAll, @


	addAll: ->
		console.log "fetch"
		@$el.empty()
		console.log @collection
		@$el.append(@template(posts: @collection))


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
		@user = new Slinggit.Models.User(id: @json.id, name: @json.name)

		# Primary DOM elements.  Intance variable for DOM elements that
		# we will use multiple time.  Keeps us from searching the COM for
		# the same element over and over
		@$postListHeader = $("#userPosts").find('header')
		@$postFilters = $("#postsFilters")
		
		# Templates
		@headerTemplate = JST["posts/post_list_title"]

		# Bound events.  Might switch to its own view
		@$postFilters.find('a').click @changeActive

	routes:
		""   :  "root"
		"posted"  :  "currentPosts"
		"watching":  "watchedPosts"
		"archived":  "archivedPosts"

	root: =>
		@posts.reset @json.open_posts

	currentPosts: =>
		@posts.reset @json.open_posts
		@changePostHeader(@user.get("name"))


	watchedPosts: =>
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=watched"
		@posts.fetch
			success: =>
				@changePostHeader("Watched")
				@posts.restoreDefualtUrl()
			error: =>
				# error code

	archivedPosts: =>
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=archived"
		@posts.fetch
			success: =>
				@changePostHeader("Archived")
				@posts.restoreDefualtUrl()
			error: =>
				# error code

	changePostHeader: (title)=>
		@$postListHeader.empty().append(@headerTemplate(label: title, posts: @posts))

	changeActive: (e)=>
		@$postFilters.find('a').removeClass("active")
		$(e.currentTarget).addClass("active")
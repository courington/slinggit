# File: controllers/users/show

## Imports
Slinggit.Collections ||= {}
Slinggit.Views.Posts ||= {}
Slinggit.Models ||= {}

## Module
class Slinggit.Controllers.Users.Show extends Backbone.Router
	initialize: (options)->
		@json = options.json
		@posts = new Slinggit.Collections.Posts(post_list_type: "posted")
		@postListView = new Slinggit.Views.Posts.PostListView( collection: @posts )
		@user = new Slinggit.Models.User(id: @json.id, name: @json.name, current_user: @json.current_user)

		# Primary DOM elements.  Intance variable for DOM elements that
		# we will use multiple time.  Keeps us from searching the COM for
		# the same element over and over
		@$postListHeader = $("#userPosts").find('header')
		@$postFilters = $("#postsFilters")
		@$posted = $("#posted")
		@$watching = $("#watching")
		@$archived = $("#archived")
		
		# Templates
		@headerTemplate = JST["posts/post_list_title"]

	routes:
		""   :  "root"
		"posted"  :  "currentPosts"
		"watching":  "watchedPosts"
		"archived":  "archivedPosts"

	root: =>
		@posts.setPostType("posted")
		@posts.reset @json.open_posts
		@changePostHeader(if @user.get("current_user") then "My" else @user.get("name"))
		@changeActive(@$posted)

	currentPosts: =>
		@root()

	watchedPosts: =>
		@posts.setPostType("watched")
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=watched"
		@posts.fetch
			success: =>
				@changeActive(@$watching)
				@changePostHeader "Watched"
				@posts.restoreDefualtUrl()
			error: =>
				# error code

	archivedPosts: =>
		@posts.setPostType("archived")
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=archived"
		@posts.fetch
			success: =>
				@changeActive(@$archived)
				@changePostHeader "Archived"
				@posts.restoreDefualtUrl()
			error: =>
				# error code

	changePostHeader: (title)=>
		@$postListHeader.empty().append(@headerTemplate(label: title, posts: @posts))

	changeActive: (a)=>
		@$postFilters.find('a').removeClass("active")
		a.addClass("active")
# File: controllers/users/show

## Imports
Slinggit.Collections ||= {}
Slinggit.Views.Posts ||= {}
Slinggit.Models ||= {}

## Module
class Slinggit.Controllers.Users.Show extends Backbone.Router
	initialize: (options)->
		@json = $("#userJson").data('user')
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

		# Putting the click event in the initializer for now.  Probably should factor
		# this out into a view
		@$postFilters.find('a').live "click", (e)=>
			e.preventDefault()
			yOffset = window.pageYOffset;
			locations = e.currentTarget.href.split "#"
			window.location.hash = locations[1]
			window.scrollTo( 0, yOffset );
			false

	routes:
		""        :  "root"
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
		@changeActive(@$watching)
		@changePostHeader "Watched"
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=watched"
		@posts.fetch
			success: =>
				@posts.restoreDefualtUrl()
			error: =>
				# error code

	archivedPosts: =>
		@posts.setPostType("archived")
		@changeActive(@$archived)
		@changePostHeader "Archived"
		@posts.url = "/posts/filtered_list.json?id=#{@user.get('id')}&filter=archived"
		@posts.fetch
			success: =>
				@posts.restoreDefualtUrl()
			error: =>
				# error code

	changePostHeader: (title)=>
		@$postListHeader.empty().append(@headerTemplate(label: title, posts: @posts))

	changeActive: (a)=>
		@$postFilters.find('a').removeClass("active")
		a.addClass("active")




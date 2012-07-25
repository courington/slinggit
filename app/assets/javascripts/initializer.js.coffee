#
#  I'm not 100% how I want this to work yet.  I'm thinking we can have initializers
#  for some of our more major model objects
#

#  Global
@Slinggit = 
	Views:
		Posts: {}
		Users: {}
	Controllers:
		Posts: {}
		Users: {}
	Models: {}
	Collections: {}

	# Probably going to refactor these initializers.
	initUsersShow: ->
		new Slinggit.Controllers.Users.Show()
		Backbone.history.start()



# File: models/users

## Module
class Slinggit.Models.User extends Backbone.Model
	initialize: ->
		console.log @.get("name")
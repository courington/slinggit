## Module
class DropdownView extends Backbone.View
	el: "#accountDropDown"
	
	initialize: ()->
		@dropdown = $(".nav_dropDown")

	events: 
		"click .BTN_nav_dropDown": "toggle"

	toggle: (e)->
		console.log $(e.target)
		console.log $(e.target).is(":hidden")
		if @dropdown.is(":hidden") then @down() else @up()

	down: ->
		@dropdown.fadeIn(100)

	up: ->
		@dropdown.fadeOut(100)



## Exports
@navDropdownView = ()->
	return new DropdownView
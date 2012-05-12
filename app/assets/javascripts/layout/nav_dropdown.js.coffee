## Module
class DropdownView extends Backbone.View
	el: "#accountDropDown"
	
	initialize: ()->
		console.log "init"
		@dropdown = $(".nav_dropDown")

	events: 
		"click .BTN_nav_dropDown": "toggle"

	toggle: (e)->
		console.log $(e.target)
		console.log $(e.target).is(":hidden")
		if @dropdown.is(":hidden") then @down() else @up()

	down: ->
		@dropdown.slideDown(100)

	up: ->
		@dropdown.slideUp(100)



## Exports
@navDropdownView = ()->
	return new DropdownView
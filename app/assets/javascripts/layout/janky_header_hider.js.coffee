class JankyHeaderHider extends Backbone.View
	el: "body"

	initialize: (options)->
		console.log "init"

	events:
		"focusin input": "hideHeader"
		"focusin textarea": "hideHeader"

	hideHeader: (e)->
		console.log "Add .headerHideOnFocus"
		console.log e.target.id
		$(e.target).focusout @showHeader

	showHeader: (e)->
		console.log "Remove .headerHideOnFocus"
		$('input, textarea').focus ()->
			console.log $(@).length
			if @ is ""
				console.log "hide"
		




## Export
$(document).ready ->
	new JankyHeaderHider
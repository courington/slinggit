## Module
class PhotoSelector extends Backbone.View
	el: "#photoSelectorWrapper"

	initialize: (options)->
		@$formEl = $("#edit_user_#{@options.i}")
		@$hidden = $("#user_photo_source")
		console.log @$formEl

	events:
		"click img": "selectPhoto"

	selectPhoto: (e)->
		@$hidden.attr("value", e.target.id)
		@$formEl.submit()



## Exports
window.initPhotoSelector = (i)->
	return new PhotoSelector i:i
## Module
class PhotoSelector extends Backbone.View
	el: "#photoSelectorWrapper"

	initialize: (options)->
		@$formEl = $("#edit_user_#{@options.i}")
		@$hidden = $("#user_photo_source")
		@submit = @options.submit

	events:
		"click img": "selectPhoto"

	selectPhoto: (e)->
		console.log e.target.id
		@$hidden.attr("value", e.target.id)
		@$formEl.submit() if @submit



## Exports
window.initPhotoSelector = (i, s)->
	return new PhotoSelector i:i, submit:s
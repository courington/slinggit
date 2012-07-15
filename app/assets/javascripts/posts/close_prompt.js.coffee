## Module
class ClosePostModal extends Backbone.View
	el: "#postContolsActions"

	initialize: (options)->
		_.bindAll @
		@$modal = $("#closePromptModal")
		# We have to move this to the body element to get it out of the
		# page wrapper
		@$modal.appendTo("body")

	events:
		"click #archivePrompt" : "showModal"

	showModal: ()->
		@$modal.modal('show')


window.initPostModal = ()->
	new ClosePostModal
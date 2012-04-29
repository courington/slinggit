
## Module
class Photo extends Backbone.View
	el: "#photoControlGroup"

	initialize: ->
		$("#post_photo").bind("change", @showFile)

	events:
		"click #fileSelect": "trigger"

	trigger: (e)->
		if $('#post_photo').length 
			$('#post_photo').trigger "click"
		e.preventDefault();	

	showFile: (el)->
		file = this.files[0]
		imageType = /image.*/

		if file.type.match imageType
			img = document.createElement("img")
			img.classList.add "obj"
			img.file = file
			$('#fileSelect').remove()
			$('#photoControlGroup').find('.controls').append(img)
			reader = new FileReader()
			reader.onload = ((aImg)->
				(e)-> aImg.src = e.target.result)(img)
			reader.readAsDataURL(file)	

$(document).ready ->
	@photo = new Photo
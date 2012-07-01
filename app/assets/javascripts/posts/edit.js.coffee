
## Module
class Photo extends Backbone.View
	el: "#photoControlGroup"

	initialize: ->
		$("#post_photo").bind("change", @showFile)
		@changePhotoEl = "<a href='#' id='changeFileSelect'>Change photo</a>"

	events:
		"click #fileSelect": "trigger"
		"click #post_photo": "photoInfo"

	photoInfo: (e)->
		alert e

	trigger: (e)->
		if $('#post_photo').length 
			$('#post_photo').trigger "click"
		e.preventDefault();	

	showFile: (el)->
		file = @files[0]
		console.log file
		imageType = /image.*/

		if file.type.match imageType
			img = document.createElement("img")
			img.classList.add "obj"
			img.classList.add "img_border"
			img.file = file
			$('#fileSelect').text("Change photo")
			$controls = $('#photoControlGroup').find('.controls')
			imageToRemove = $controls.find('.obj')
			imageToRemove.remove()
			$controls.remove('.obj').append(img)
			reader = new FileReader()
			reader.onload = ((aImg)->
				(e)-> aImg.src = e.target.result)(img)
			reader.readAsDataURL(file)	

$(document).ready ->
	@photo = new Photo
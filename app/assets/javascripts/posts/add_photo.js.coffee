
## Module
class Photo extends Backbone.View
  el: "#addPhotoControlGroup"

  initialize: ->
    $("#add_post_photo").bind("change", @showFile)

  events:
    "click #photoSelect": "trigger"

  trigger: (e)->
    if $('#add_post_photo').length
      $('#add_post_photo').trigger "click"
    e.preventDefault();

  showFile: (el)->
    file = @files[0]
    imageType = /image.*/

    if file.type.match imageType
      $('#addImageForm').submit();

$(document).ready ->
  @photo = new Photo
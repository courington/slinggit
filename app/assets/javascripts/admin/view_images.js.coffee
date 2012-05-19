#module
class AdminPhotoView extends Backbone.View
  tagName: "article"
  className: "postedPhoto"

  initialize: (options)->
    @$photoContent = @options.photoContent

  render: ->
    @$photoContent.append @el

#exports @=window at this tab level
@createPhotoArticle = (photoWrapper)->
  return new AdminPhotoView({photoContent: photoWrapper})

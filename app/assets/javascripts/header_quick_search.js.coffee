## Module
class HeaderSearch extends Backbone.View
  el: "#mainHeader"

  initialize: (options) ->
    _.bindAll @
    @hideSearch()
    @isUp = true

  events:
    "click .quickSearchLabel": "upDown"

  hideSearch: ->
    @$el.addClass "headerUp"

  upDown: (e) ->
    if @isUp and @$el.hasClass("headerUp")
      @$el.removeClass("headerUp")
      @isUp = false
    else if not @isUp and not @$el.hasClass("headerUp")
      @$el.addClass "headerUp"
      @isUp = true

## Export
window.initiHeaderSearch = ->
  new HeaderSearch()
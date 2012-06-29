## Module
class HeaderSearch extends Backbone.View
  el: "#mainHeader"

  initialize: (options) ->
    _.bindAll @
    @$searchBox = $("#quickSearch")
    @hideSearch()
    @isUp = true

  events:
    "click .quickSearchLabel": "upDown"

  hideSearch: ->
    @$el.addClass "headerUp"

  upDown: (e) ->
    if @isUp and @$el.hasClass("headerUp")
      @$el.removeClass("headerUp")
      console.log @$searchBox
      @$searchBox.focus()
      @isUp = false
    else if not @isUp and not @$el.hasClass("headerUp")
      @$el.addClass "headerUp"
      @$searchBox.blur()
      @isUp = true

## Export
window.initiHeaderSearch = ->
  new HeaderSearch()
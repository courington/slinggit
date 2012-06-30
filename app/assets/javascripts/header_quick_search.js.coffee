## Module
class HeaderSearch extends Backbone.View
  el: "#mainHeader"

  initialize: (options) ->
    _.bindAll @
    @$searchBox = $("#quickSearch")
    @isUp = true

  events:
    "click .quickSearchLabel": "upDown"
    "focus #quickSearch": "setPosition"

  upDown: (e) ->

    if @isUp and @$el.hasClass("headerUp")
      @$el.removeClass "headerUp"
      $("html, body").animate
        scrollTop: "0"
      , 100
      @isUp = false

    else if not @isUp and not @$el.hasClass("headerUp")
      #@$searchBox.blur()
      @$el.removeClass "headerTop"
      @$el.addClass "headerUp"
      @isUp = true

  setPosition: (e)->
    @isFocused = true
    @$el.addClass "headerTop"

  
## Export
window.initiHeaderSearch = ->
  new HeaderSearch
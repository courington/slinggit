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
      @$searchBox.focus()
      # $("html, body").animate
      #   scrollTop: "0"
      # , 100
      # , =>
      #     $("#quickSearch").focus()
      @isUp = false

    else if not @isUp and not @$el.hasClass("headerUp")
      #@$searchBox.blur()
      @$el.attr "style", ""
      @$el.addClass "headerUp"
      @isUp = true

  setPosition: (e)->
    @$el.css("top", "0")

  
## Export
window.initiHeaderSearch = ->
  new HeaderSearch
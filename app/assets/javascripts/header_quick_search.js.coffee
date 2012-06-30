## Module
class HeaderSearch extends Backbone.View
  el: "#mainHeader"

  initialize: (options) ->
    _.bindAll @
    @$searchBox = $("#quickSearch")
    @isUp = true

  events:
    "click .quickSearchLabel": "upDown"
    #"focus #quickSearch": "setPosition"

  upDown: (e) ->

    if @isUp and @$el.hasClass("headerUp")
      @$el.removeClass "headerUp"
      @$searchBox.focus()
      @isUp = false

    else if not @isUp and not @$el.hasClass("headerUp")
      if @$searchBox.val() isnt ""
        document.location.href = "/posts/results/#{$('#quickSearch').val()}"
      else
        @$searchBox.blur()
        @$el.addClass "headerUp"
        @isUp = true

  # Not being used right now, but keeping until we're satified with how it works.
  setPosition: (e)->
    @$el.css({"top": "0", "position": "static"})
    $("html, body").animate
        scrollTop: "0"
      , 100
      , =>
          @$el.attr "style", ""


  
## Export
window.initiHeaderSearch = ->
  new HeaderSearch
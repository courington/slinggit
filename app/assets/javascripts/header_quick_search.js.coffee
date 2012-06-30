## Module
class HeaderSearch extends Backbone.View
  el: "#mainHeader"

  initialize: (options) ->
    _.bindAll @
    @$searchBox = $("#quickSearch")
    @isUp = true

  events:
    "click .quickSearchLabel": "upDown"

  upDown: (e) ->
    if @isUp and @$el.hasClass("headerUp")
      @$el.removeClass "headerUp"
      $("html, body").animate {scrollTop:0}, 200
      @$el.scrollTop(0)
      @$searchBox.focus()
      @isUp = false
    else if not @isUp and not @$el.hasClass("headerUp")
      @$searchBox.blur()
      @$el.addClass "headerUp"
      @isUp = true

  
## Export
window.initiHeaderSearch = ->
  new HeaderSearch
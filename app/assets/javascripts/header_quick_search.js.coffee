## Module
class HeaderSearch extends Backbone.View
  el: "#mainHeader"

  initialize: (options) ->
    _.bindAll @
    @hideSearch()

  events:
    "click .quickSearchLabel": "upDown"

  hideSearch: ->
    @$el.addClass "headerUp"

  upDown: (e) ->
    console.log "anything"

## Export
window.initiHeaderSearch = ->
  new HeaderSearch()
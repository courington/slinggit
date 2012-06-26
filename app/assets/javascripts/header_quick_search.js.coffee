## Module
HeaderSearch = Backbone.View.extend
  initialize: (options) ->
    _.bindAll @
    @hideSearch()
    @$header = $("header")

  events:
    "click .quickSearchLabel": "upDown"

  hideSearch: ->
    $("header").addClass "headerUp"
    console.log "in hide"

  upDown: (e) ->
    console.log @

## Export
window.initiHeaderSearch = ->
  new HeaderSearch()
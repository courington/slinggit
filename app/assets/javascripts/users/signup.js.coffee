
## Module
class EmailValidation extends Backbone.View

	initialize: (options)->
		# This keeps @ as @ in all of our methods.  Very
  		# handy with jquery event handeling
  		_.bindAll @
  		@$userEmail = $("user_email")
  		@url = @options.url
  		@resetUrl = @options.resetUrl
  		@permissionGranted = @options.granted
  		console.log @permissionGranted
  		@noThanks = @options.noThanks
  		console.log @noThanks
  		@hideFields()
  		if @permissionGranted or @noThanks then @showHiddenFields()


  	hideFields: ->
  		$(".form_hiddenFields").hide()
  		$("#form_signUpActions").hide()
  		$("#emailAvailabilityNotification").hide()


  	showHiddenFields: ->
  		$(".form_hiddenFields").show()
  		$("#form_signUpActions").hide()
  		if @permissionGranted then $("legend").html "You are authenticated with Twitter"

	
	events:
		"blur #user_email":                   "checkEmailAddress"
		"keyup input":                        "hideErrorsAndNotifications"
		"keyup #user_email":                  "validateEmail"
		"click #noThanksBTN":                 "callNoThanks"
		"click #twitterBTN":                  "twitterAuthorize"
		"click #signUpStartOverLink":         "startOver"
		"click #emailSuggestionReplaceLink":  "swapEmailWithSuggested"

	
	checkEmailAddress: (e)->
		domains = [ "hotmail.com", "gmail.com", "aol.com", "msn.com", "yahoo.com", "pixorial.com", "slinggit.com" ]
		$(e.target).mailcheck
		  domains: domains
		  suggested: (element, suggestion) ->
		    $("#emailSuggestion").remove()
		    @$userEmail.parent().append "<span id='emailSuggestion'>Did you mean <a href='#' id='emailSuggestionReplaceLink'>" + suggestion.full + "</a></span>"

		  empty: (element) ->
		    $("#emailSuggestion").remove()


	validateEmail: (e)->
		email_address = @$userEmail.val()
		emailRegex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
		if emailRegex.test(email_address)
		  $.ajax(
		    type: "POST"
		    url: @url
		    data:
		      email: email_address
		  ).done (response) ->
		    if response is "unavailable"
		      $ "#user_email"
		      $("#emailAvailabilityNotification").html "<div id=\"error_explanation\"><ul><li>* That email has already been registered.  <a href=\"#\">forgot password?</a></li></ul></div>"
		      $("#emailAvailabilityNotification").show()
		    else
		      $("#emailAvailabilityNotification").html ""
		      $("#emailAvailabilityNotification").hide()

	
	hideErrorsAndNotifications: (e)->
		$("#error_explanation").hide()
		$(".field_with_errors").removeClass "field_with_errors"
		$(".alert").hide()
		$("html, body").animate
		  scrollTop: 0
		, "fast"


	swapEmailWithSuggested: ->
		@$userEmail.val($('#emailSuggestionReplaceLink').text())
		$("#emailSuggestion").remove()


	callNoThanks: (e)->
		e.preventDefault()
		$("#form_signUpActions").hide()
		$(".form_hiddenFields").show()
		hideErrorsAndNotifications()
		$.ajax url: "<%= url_for :controller => :users, :action => :set_no_thanks %>"


	twitterAuthorize: (e)->
		e.preventDefault()
		$("#twitter_authenticate").val(true)
		$("form").submit()


	startOver: (e)->
		e.preventDefault()
		$(".form_hiddenFields").hide()
		$("#form_signUpActions").show()
		$("#user_name").val ""
		$("#user_email").val ""
		$("legend").html "Create your profile"
		$("#emailSuggestion").remove()
		hideErrorsAndNotifications()
		$.ajax url: "<%= url_for :controller => :users, :action => :reset_page_session %>"


## Exports
@emailValidationView = (url, resetUrl, sessionGranted, noThanks)->
	return new EmailValidation({ url: url, resetUrl: resetUrl, granted: sessionGranted, noThanks: noThanks })











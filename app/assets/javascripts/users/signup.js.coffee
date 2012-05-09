
## Module
class EmailValidation extends Backbone.View

	initialize: (options)->
		# This keeps @ as @ in all of our methods.  Very
  		# handy with jquery event handeling
  		_.bindAll @
  		@$userEmail = $("user_email")
  		@url = @options.url

	
	events:
		"blur #user_email":   "checkEmailAddress"
		"keyup input":        "hideErrorsAndNotifications"
		"keyup #user_email":  "validateEmail"

	
	checkEmailAddress: (e)->
		domains = [ "hotmail.com", "gmail.com", "aol.com", "msn.com", "yahoo.com", "pixorial.com", "slinggit.com" ]
		$(e.target).mailcheck
		  domains: domains
		  suggested: (element, suggestion) ->
		    $("#emailSuggestion").remove()
		    @$userEmail.parent().append "<span id='emailSuggestion'>Did you mean <a href='#' onclick='swapEmailWithSuggested()' id='emailSuggestionReplaceLink'>" + suggestion.full + "</a></span>"

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


## Exports
@emailValidationView = (url)->
	return new EmailValidation({ url: url })
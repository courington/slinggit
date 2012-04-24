require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  private

  	def client
  		@client ||= Twitter::Client.new(:oauth_token => current_user.twitter_atoken, :oauth_token_secret => current_user.twitter_asecret)
  	end	

  	# This is terrrible, but I just need it to work for now!
  	def slinggit_client
  		# Dev
  		# @slinggit_client ||= Twitter::Client.new(:oauth_token => "561831843-mHAqcKLJfFyCSQOXvlyH5fCvHRlRhRqMFDPNMS9h", :oauth_token_secret => "T7yvd3FfhpVJacLS6zjFO3yrXl8HDurhfXLq3AQL8")
  		# Prod
  		@slinggit_client ||= Twitter::Client.new(:oauth_token => "561831843-vpq6NXNaQ8FGXR07D8GETEO6WxxkMKGbHMZ7qefk", :oauth_token_secret => "fEvbYhkf8PKHs8CeXGE7JhB2lf39NSKKDDTA4y0U0s")
  	end

end

# require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  # Catch Unauthorized error and ask the user to reauthenticate
  rescue_from Twitter::Error::Unauthorized, with: :ask_to_reauthenticate

  private

  def client
    @client ||= Twitter::Client.new(oauth_token: current_user.twitter_atoken, oauth_token_secret: current_user.twitter_asecret)
  end

  # May need to refactor how we're setting up the slinggit client in order to handle authentication
  # coming back from twitter.  For instance if we were to change settings in our twitter app, this would break.
  def slinggit_client
    @slinggit_client ||= Twitter::Client.new(oauth_token: Rails.configuration.slinggit_client_atoken, oauth_token_secret: Rails.configuration.slinggit_client_asecret)
  end

  def setup_twitter_call(callback_uri = callback_url)
    request_token = oauth_consumer.get_request_token(:oauth_callback => callback_uri)
    session['rtoken'] = request_token.token
    session['rsecret'] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def oauth_consumer
    @oauth_consumer ||= OAuth::Consumer.new(Twitter.consumer_key, Twitter.consumer_secret, site: 'http://api.twitter.com', request_endpoint: 'http://api.twitter.com', sign_in: true)
  end

  def ask_to_reauthenticate
    reset_session
    flash[:warning] = "Whoops! Looks like we need you to reauthorize your Twitter account."
    redirect_to reauthorize_twitter_path
  end

end

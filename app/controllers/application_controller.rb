# require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  # Catch Unauthorized error and ask the user to reauthenticate
  rescue_from Twitter::Error::Unauthorized, with: :ask_to_reauthenticate

  private

  def log_user_login(user = nil)
    if not request.blank?
      user = current_user || user
      UserLogin.create(
          :user_id => user.id,
          :user_agent => "#{request.user_agent}",
          :ip_address => "#{request.remote_ip}",
          :url_referrer => "#{request.referrer}",
          :login_source => "#{request.parameters[:controller]}/#{request.parameters[:action]}",
          :session_json => "#{request.env['rack.session'].to_json}",
          :paramaters_json => "#{request.filtered_parameters.to_json}"
      )
    end
  end

  def create_api_account(options = {})
    if not options.blank?
      case options[:source]
        when :twitter
          if not ApiAccount.exists?(['user_id = ? AND api_id = ?', options[:user_object].id, options[:api_object].user['id'].to_s])
            ApiAccount.create(
                :user_id => options[:user_object].id,
                :api_id => options[:api_object].user['id'],
                :api_source => 'twitter',
                :oauth_token => options[:api_object].oauth_token,
                :oauth_secret => options[:api_object].oauth_token_secret,
                :real_name => options[:api_object].user['name'],
                :user_name => options[:api_object].user['screen_name'],
                :image_url => options[:api_object].user['profile_image_url'],
                :description => options[:api_object].user['description'],
                :language => options[:api_object].user['lang'],
                :location => options[:api_object].user['location'],
                :primary_account => ApiAccount.exists?(['user_id = ? AND primary_account = "1"', options[:user_object].id])? "0" : "1",
                :status => 'active'
            )
          end
        else
          #do nothing
      end
    end
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

  def valid_json?(json_string)
    begin
      JSON.parse(json_string)
      return true
    rescue Exception => e
      return false
    end
  end

end

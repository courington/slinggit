# require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

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
          if not ApiAccount.first(:conditions => ['user_id = ? AND api_id = ?', options[:user_object].id, options[:api_object].user['id'].to_s], :select => 'id')
            status = 'primary'
            if ApiAccount.first(:conditions => ['user_id = ? AND status = "primary"', options[:user_object].id], :select => 'id')
              status = 'active'
            end

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
                :status => status
            )
          end
        else
          #do nothing
      end
    end
  end

  def update_api_account(options = {})
    if not options.blank?
      case options[:source]
        when :twitter
          if api_account = ApiAccount.first(:conditions => ['user_id = ? AND api_id = ?', options[:user_object].id, options[:api_object].user['id'].to_s], :select => 'id')
            api_account.update_attributes(
                :oauth_token => options[:api_object].oauth_token,
                :oauth_secret => options[:api_object].oauth_token_secret,
                :image_url => options[:api_object].user['profile_image_url'],
                :description => options[:api_object].user['description'],
                :location => options[:api_object].user['location'],
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

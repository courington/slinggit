# require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  def redirect
    redirect_info = params[:path]
    if not redirect_info.blank?
      if redirect_info.include? '/'
        redirect_to '/404.html'
      else
        if user = User.first(:conditions => ['name = ?', redirect_info])
          redirect_to :controller => :posts, :action => :show, :id => user.id
        elsif redirect = Redirect.first(:conditions => ['key_code = ?', redirect_info])
          redirect.update_attribute(:clicks, redirect.clicks += 1)
          redirect_to redirect.target_uri
        else
          flash[:error] = "Darn, we couldn't find what you were looking for.  Try using the quick search feature to find items for sale.'"
        end
      end
    else
      redirect_to :controller => :static_pages, :action => :home
    end
  end

  private

  def passes_limitations?(limitation_type)
    if signed_in?
      case limitation_type
        when :posts
          user_limitations = UserLimitation.first(:conditions => ['limitation_type = "posts" AND user_id = ?', current_user.id])
          if user_limitations
            past_time_contraint = Time.now.advance(user_limitations.frequency_type.to_sym => user_limitations.frequency * -1)
            number_of_posts = Post.count(:conditions => ['created_at >= ?', past_time_contraint])
            if number_of_posts >= user_limitations.user_limit
              return false
            else
              return true
            end
          else
            return true
          end
      end
    else
      return true
    end
  end

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

            api_account = ApiAccount.create(
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
                :reauth_required => 'no',
                :status => status
            )
            return [true, api_account]
          else
            return [false, "You have alraedy connected that Twitter account."]
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

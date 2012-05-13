# require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  around_filter :catch_exceptions, :except => [:mobile]
  before_filter :set_timezone

  def redirect
    redirect_info = params[:path]
    if not redirect_info.blank?
      begin
        ActionController::Routing::Routes.recognize_path(params[:path], :method => :get)
        redirect_to params[:path]
      rescue
        if user = User.first(:conditions => ['name = ?', redirect_info], :select => 'id')
          redirect_to :controller => :users, :action => :show, :id => user.id
        elsif redirect = Redirect.first(:conditions => ['key_code = ?', redirect_info], :select => 'target_uri,clicks,id')
          redirect.update_attribute(:clicks, redirect.clicks += 1)
        else
          redirect_to '/404.html'
        end
      end
    else
      redirect_to :root
    end
  end

  private

  def passes_limitations?(limitation_type, user_id = nil)
    limitation_type = limitation_type.to_sym
    if current_user
      user_id = current_user.id
    end

    return true if limitation_type.blank?
    return true if user_id.blank?
    return true unless [:posts].include? limitation_type

    case limitation_type
      when :posts
        if  user_limitation = UserLimitation.first(:conditions => ['limitation_type = "posts" AND user_id = ?', user_id], :select => 'frequency_type,frequency,user_limit')
          time_frame = Time.now.advance(user_limitation.frequency_type.to_sym => user_limitation.frequency * -1)
          if Post.count(:conditions => ['created_at >= ?', time_frame]) >= user_limitation.user_limit
            return false
          end
        end
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
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] if options.blank?
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] if options[:source].blank?
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] unless [:twitter].include? options[:source].to_sym

    case options[:source].to_sym
      when :twitter
        if not ApiAccount.exists?(['user_id = ? AND api_id = ?', options[:user_object].id, options[:api_object].user['id'].to_s])
          status = 'primary'
          if ApiAccount.exists?(['user_id = ? AND status = "primary" AND api_source = ?', options[:user_object].id, options[:source]])
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
    @oauth_consumer ||= OAuth::Consumer.new(Twitter.consumer_key, Twitter.consumer_secret, site: 'https://api.twitter.com', request_endpoint: 'https://api.twitter.com', sign_in: true)
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

  def set_timezone
    #Time.zone = current_user.time_zone || 'Central Time (US & Canada)'
  end

  def catch_exceptions
    yield
  rescue => exception
    UserMailer.deliver_problem_report(exception).deliver
    if PROD_ENV
      redirect_to '/500.html'
    else
      raise exception
    end
  end

end

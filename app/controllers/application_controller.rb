# require 'twitter/authentication_helpers'
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  around_filter :catch_exceptions, :except => [:mobile]
  before_filter :set_timezone
  before_filter :verify_good_standing, :except => [:mobile, :admin, :verify_good_standing, :suspended_account]

  require "#{Rails.root}/lib/ext/string"

  #######CONSTANTS#####
  ILLICIT_PHOTO = "An illicit photo was uploaded."
  POST_VIOLATION_SOURCE = 'post'
  SLINGGIT_SECRET_HASH = Digest::SHA1.hexdigest("chris,dan,phil,chase,duck")
  ####END CONSTANTS#####

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
          redirect_to redirect.target_uri
        else
          redirect_to '/404.html'
        end
      end
    else
      redirect_to :root
    end
  end

  private

  def invite_only?
    if system_preferences[:invitation_only] and system_preferences[:invitation_only] == "on"
      return true
    else
      return false
    end
  end

  #returns a key value pair of system preferences
  def system_preferences
    #TODO remove true from the following line after presentation.  Dont want the invitation only session to get bogged up during pres
    if true or session[:system_preferences].blank?
      active_preferences = HashWithIndifferentAccess.new()
      system_preferences = SystemPreference.all(:conditions => ['active = ?', true])
      system_preferences.each do |preference|
        if (preference.start_date.blank? or preference.start_date <= Date.now) and (preference.end_date.blank? or preference.end_date >= Date.now)
          if preference.constraints.blank? or eval(preference.constraints)
            active_preferences[preference.preference_key] = preference.preference_value
          end
        end
      end
      session[:system_preferences] = active_preferences
      return active_preferences
    else
      return session[:system_preferences]
    end
  end

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
          if Post.count(:conditions => ['created_at >= ? AND user_id = ?', time_frame, user_id]) >= user_limitation.user_limit
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
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] unless [:twitter, :facebook].include? options[:source].to_sym

    case options[:source].to_sym
      when :twitter
        if not ApiAccount.exists?(['user_id = ? AND api_id = ? AND api_source = ? AND status != ?', options[:user_object].id, options[:api_object].user['id'].to_s, options[:source], STATUS_DELETED])
          status = STATUS_PRIMARY
          if ApiAccount.exists?(['user_id = ? AND status = ? AND api_source = ?', options[:user_object].id, STATUS_PRIMARY, options[:source]])
            status = STATUS_ACTIVE
          end

          api_account = ApiAccount.create(
              :user_id => options[:user_object].id,
              :api_id => options[:api_object].user['id'],
              :api_source => options[:source],
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
      when :facebook
        if not ApiAccount.exists?(['user_id = ? AND api_id = ? AND api_source = ? AND status != ?', options[:user_object].id, options[:api_object]['id'].to_s, options[:source], STATUS_DELETED])
          status = STATUS_PRIMARY
          if ApiAccount.exists?(['user_id = ? AND status = ? AND api_source = ?', options[:user_object].id, STATUS_PRIMARY, options[:source]])
            status = STATUS_ACTIVE
          end

          api_account = ApiAccount.create(
              :user_id => options[:user_object].id,
              :api_id => options[:api_object]['id'],
              :api_source => options[:source],
              :oauth_token => nil,
              :oauth_secret => options[:api_object]['access_token'],
              :oauth_expiration => Time.now.advance(:seconds => options[:api_object]['expires'].to_i),
              :real_name => options[:api_object]['name'],
              :user_name => options[:api_object]['username'],
              :image_url => "http://graph.facebook.com/#{options[:api_object]['username']}/picture",
              :description => nil,
              :language => options[:api_object]['languages'].blank? ? nil : options[:api_object]['languages'].first['name'],
              :location => options[:api_object]['location']['name'].blank? ? nil : options[:api_object]['location']['name'],
              :reauth_required => 'no',
              :status => status
          )
          return [true, api_account]
        else
          return [false, "You have alraedy connected that Facebook account."]
        end
    end
  end

  def update_api_account(options = {})
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] if options.blank?
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] if options[:source].blank?
    return [false, "Sorry, an unexpected error has occured.  Please try again in a few minutes."] unless [:twitter].include? options[:source].to_sym

    if not options.blank?
      case options[:source]
        when :twitter
          if api_account = ApiAccount.first(:conditions => ['user_id = ? AND api_id = ? AND api_source = ?', options[:user_object].id, options[:api_object].user['id'].to_s, options[:source]], :select => 'id')
            api_account.update_attributes(
                :oauth_token => options[:api_object].oauth_token,
                :oauth_secret => options[:api_object].oauth_token_secret,
                :image_url => options[:api_object].user['profile_image_url'],
                :description => options[:api_object].user['description'],
                :location => options[:api_object].user['location'],
            )
          end
        when :facebook
          api_account.update_attributes(
              :oauth_secret => options[:api_object]['access_token'],
              :oauth_expiration => Time.now.advance(:seconds => options[:api_object]['expires'].to_i)
          )
        else
          #do nothing
      end
    end
  end

  def delete_api_account(api_to_delete)
    if not api_to_delete.blank?
      was_primary = api_to_delete.status == STATUS_PRIMARY
      if was_primary
        #we need at least one primary if there are api_accounts of this type remaining
        if next_primary_api_account = ApiAccount.first(:conditions => ['user_id = ? AND api_source = ? AND status != ?', api_to_delete.user_id, api_to_delete.api_source, STATUS_DELETED])
          next_primary_api_account.update_attribute(:status, STATUS_PRIMARY)
        end
      end
      api_to_delete.update_attribute(:status, STATUS_DELETED)
      return [true, next_primary_api_account]
    else
      return [false, "Oops, something went wrong.  Please try again later."]
    end
  end

  def setup_twitter_call(callback_uri = callback_url)
    request_token = oauth_consumer.get_request_token(:oauth_callback => callback_uri)
    session['rtoken'] = request_token.token
    session['rsecret'] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def setup_facebook_call(callback_uri = facebok_callback_url, scope)
    #state represents a random string that we can check in the callback to prevent cross site request forgery
    #I have chosen to use a digest of the users email address plus the slinggit secret so that I can build it up again without using session

    state = Digest::SHA1.hexdigest(current_user.email + SLINGGIT_SECRET_HASH)
    redirect_to "https://graph.facebook.com/oauth/authorize?client_id=#{Rails.configuration.facebook_app_id}&redirect_uri=#{callback_uri}&scope=#{scope}&state=#{state}"
  end

  def oauth_consumer
    @oauth_consumer ||= OAuth::Consumer.new(Twitter.consumer_key, Twitter.consumer_secret, site: 'https://api.twitter.com', request_endpoint: 'https://api.twitter.com', sign_in: true)
  end

  def ask_to_reauthenticate
    reset_session
    flash[:warning] = "Oops! Looks like we need you to reauthorize your Twitter account."
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

  ###BEFORE FILTERS####
  def verify_good_standing
    if signed_in?
      # suspended users are allowed to login, they're just notified that their accounts are suspeneded.
      if current_user.is_suspended?
        flash.now[:notice] = 'It seems as though you are currently in time out due to a terms of service violation.  If you feel you have reached this message in error, please contact support@slinggit.com' and return
        # if the user is deleted and doesn't have a reactivation_code, they've been banned, banned so hard!
      elsif current_user.is_banned?
        if signed_in?
          sign_out
          reset_session
        end
        redirect_to '/deleted_account' and return
        # if the user is deleted and does have a reactivation_cod, they've removed themselves.  We might want
        # to be more friendly to them
      elsif current_user.is_self_destroyed?
        if signed_in?
          sign_out
          reset_session
        end
        redirect_to '/reactivate_account' and return
      end
    end
    return true
  end

  def set_timezone
    #Time.zone = current_user.time_zone || 'Central Time (US & Canada)'
  end

  def catch_exceptions
    yield
  rescue => exception
    create_problem_report(exception)
    if PROD_ENV
      redirect_to '/500.html'
    else
      raise exception
    end
  end

  def create_problem_report(exception, send_email = true)
    user_agent = nil
    ip_address = nil
    url_referrer = nil

    if not request.blank?
      user_agent = request.user_agent if request.user_agent
      ip_address = request.remote_ip if request.remote_ip
      url_referrer = request.referrer if request.referrer
    end

    ProblemReport.create(
        :exception_message => exception.message,
        :exception_class => exception.class.to_s,
        :exception_backtrace => exception.backtrace,
        :user_agent => user_agent,
        :ip_address => ip_address,
        :url_referrer => url_referrer,
        :signed_in_user_id => signed_in? ? current_user.id : nil,
        :send_email => send_email
    )
  end

end


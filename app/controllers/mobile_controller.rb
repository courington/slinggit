class MobileController < ApplicationController
  #before_filter :require_post
  before_filter :set_state
  before_filter :validate_post_data_is_valid_json, :only => [:create_twitter_post, :resubmit_twitter_post, :delete_twitter_post, :update_twitter_post]

  ERROR_STATUS = "error"
  SUCCESS_STATUS = "success"

  def user_signup
    if not params[:user_name].blank?
      if not params[:email].blank?
        if not params[:password].blank?
          user_name = params[:user_name].downcase
          email = params[:email].downcase
          if not User.exists?(['email = ?', email])
            if not User.exists?(['name = ?', user_name])
              user = User.create(
                  :name => params[:user_name],
                  :email => params[:email],
                  :password => params[:password],
                  :password_confirmation => params[:password]
              )

              log_user_login(user)
              mobile_auth_token = create_or_update_mobile_auth_token(user.id)
              render :text => success_response(
                  :mobile_auth_token => mobile_auth_token
              )
            else
              render :text => error_responce(
                  :error_location => 'user_signup',
                  :error_reason => 'unavailable - user_name',
                  :error_code => '409',
                  :friendly_error => 'That user name has already been registered.'
              )
            end
          else
            render :text => error_responce(
                :error_location => 'user_signup',
                :error_reason => 'unavailable - email',
                :error_code => '409',
                :friendly_error => 'That email address has already been registered.'
            )
          end
        else
          render :text => error_responce(
              :error_location => 'user_signup',
              :error_reason => 'missing required_paramater - password',
              :error_code => '403',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render :text => error_responce(
            :error_location => 'user_signup',
            :error_reason => 'missing required_paramater - email',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render :text => error_responce(
          :error_location => 'user_signup',
          :error_reason => 'missing required_paramater - user_name',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def user_login
    if not params[:email].blank?
      if not params[:password].blank?
        user = User.first(:conditions => ["email = '#{params[:email]}'"])
        if user && user.authenticate(params[:password])
          log_user_login(user)
          mobile_auth_token = create_or_update_mobile_auth_token(user.id)
          render :text => success_response(
              :mobile_auth_token => mobile_auth_token
          ), :content_type => 'application/json'
        else
          render :text => error_responce(
              :error_location => 'user_login',
              :error_reason => 'password authentication failed',
              :error_code => '403',
              :friendly_error => 'Incorrect email and or password.'
          ), :content_type => 'application/json'
        end
      else
        render :text => error_responce(
            :error_location => 'user_login',
            :error_reason => 'missing required_paramater - password',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        ), :content_type => 'application/json'
      end
    else
      render :text => error_responce(
          :error_location => 'user_login',
          :error_reason => 'missing required_paramater - email',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      ), :content_type => 'application/json'
    end
  end

  def user_logout
    if not params[:mobile_auth_token].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, params[:mobile_auth_token]])
        mobile_session.update_attribute(:mobile_auth_token, nil)
        render :text => success_response(
            :logged_in => false
        ), :content_type => 'application/json'
      else
        render :text => error_responce(
            :error_location => 'user_logout',
            :error_reason => 'not found - mobile_session',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        ), :content_type => 'application/json'
      end
    else
      render :text => error_responce(
          :error_location => 'user_logout',
          :error_reason => 'missing required_paramater - mobile_auth_token',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      ), :content_type => 'application/json'
    end
  end

  def user_login_status
    if not params[:mobile_auth_token].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, params[:mobile_auth_token]])
        render :text => success_response(
            :logged_in => true
        ), :content_type => 'application/json'
      else
        render :text => success_response(
            :logged_in => false
        ), :content_type => 'application/json'
      end
    else
      render :text => error_responce(
          :error_location => 'user_login_status',
          :error_reason => 'missing required_paramater - mobile_auth_token',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      ), :content_type => 'application/json'
    end
  end

  def create_twitter_post
    if not params[:post_data].blank?
      decoded_post_data =  ActiveSupport::JSON.decode(params[:post_data])
      if not decoded_post_data['content'].blank?
      else
      end
    else
      render :text => error_responce(
          :error_location => 'create_twitter_post',
          :error_reason => 'missing required_paramater - request_data',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      ), :content_type => 'application/json'
    end
  end

  def resubmit_twitter_post

  end

  def close_twitter_post
  end

  def update_twitter_post
  end

  def get_user_twiiter_post_data
  end

  def get_slinggit_twitter_post_data
  end

  def get_user_api_accounts
  end

  private

  def create_or_update_mobile_auth_token(user_id)
    if mobile_session = MobileSession.first(:conditions => ['user_id = ? AND unique_identifier = ?', user_id, @state])
      mobile_session.update_attribute(:mobile_auth_token, Digest::SHA1.hexdigest("#{Time.now.to_i}-#{user_id}"))
    else
      mobile_session = MobileSession.create(
          :user_id => user_id,
          :unique_identifier => @state,
          :mobile_auth_token => Digest::SHA1.hexdigest("#{Time.now.to_i}-#{user_id}")
      )
    end
    return mobile_session.mobile_auth_token
  end

  def success_response(options = {})
    return {
        :status => SUCCESS_STATUS,
        :result => options
    }.to_json
  end

  def error_responce(options = {})
    return {
        :status => ERROR_STATUS,
        :result => options
    }.to_json
  end

  #----BEFORE FILTERS----#

  def set_state
    if params[:state].blank?
      render :text => error_responce(
          :error_location => 'global',
          :error_reason => 'missing required_paramater - state',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      ), :content_type => 'application/json'
      return
    else
      @state = params[:state]
    end
  end

  def require_post
    if not request.post?
      render :text => error_responce(
          :error_location => 'global',
          :error_reason => 'bad request format',
          :error_code => '400',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      ), :content_type => 'application/json'
      return
    end
  end

  def validate_request_data_is_valid_json
    if not params[:post_data].blank?
      if not params[:post_data].valid_json?
        render :text => error_responce(
            :error_location => 'global',
            :error_reason => 'post_data is not a valid json string',
            :error_code => '400',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        ), :content_type => 'application/json'
      end
    end
  end


end

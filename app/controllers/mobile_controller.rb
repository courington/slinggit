class MobileController < ApplicationController
  before_filter :require_post
  before_filter :set_state
  before_filter :set_device_name
  before_filter :set_options
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
              user = User.new(
                  :name => params[:user_name],
                  :email => params[:email],
                  :password => params[:password],
                  :password_confirmation => params[:password]
              )

              if user.save
                log_user_login(user)
                mobile_auth_token = create_or_update_mobile_auth_token(user.id)
                render_success_response(
                    :mobile_auth_token => mobile_auth_token
                )
              else
                render_error_response(
                    :error_location => 'user_signup',
                    :error_reason => 'invalide - email',
                    :error_code => '409',
                    :friendly_error => 'The email address entered is invalid.'
                )
              end
            else
              render_error_response(
                  :error_location => 'user_signup',
                  :error_reason => 'unavailable - user_name',
                  :error_code => '409',
                  :friendly_error => 'That user name has already been registered.'
              )
            end
          else
            render_error_response(
                :error_location => 'user_signup',
                :error_reason => 'unavailable - email',
                :error_code => '409',
                :friendly_error => 'That email address has already been registered.'
            )
          end
        else
          render_error_response(
              :error_location => 'user_signup',
              :error_reason => 'missing required_paramater - password',
              :error_code => '403',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'user_signup',
            :error_reason => 'missing required_paramater - email',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
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
          render_success_response(
              :mobile_auth_token => mobile_auth_token
          )
        else
          render_error_response(
              :error_location => 'user_login',
              :error_reason => 'password authentication failed',
              :error_code => '403',
              :friendly_error => 'Incorrect email and or password.'
          )
        end
      else
        render_error_response(
            :error_location => 'user_login',
            :error_reason => 'missing required_paramater - password',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'user_login',
          :error_reason => 'missing required_paramater - email',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def user_logout
    if not params[:mobile_auth_token].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, params[:mobile_auth_token]])
        mobile_session.update_attribute(:mobile_auth_token, nil)
        render_success_response(
            :logged_in => false
        )
      else
        render_error_response(
            :error_location => 'user_logout',
            :error_reason => 'not found - mobile_session',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'user_logout',
          :error_reason => 'missing required_paramater - mobile_auth_token',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def user_login_status
    if not params[:mobile_auth_token].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, params[:mobile_auth_token]])
        render_success_response(
            :logged_in => true
        )
      else
        render_success_response(
            :logged_in => false
        )
      end
    else
      render_error_response(
          :error_location => 'user_login_status',
          :error_reason => 'missing required_paramater - mobile_auth_token',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def create_twitter_post
    if not params[:post_data].blank?
      decoded_post_data = ActiveSupport::JSON.decode(params[:post_data])
      if not decoded_post_data['content'].blank?
      else
      end
    else
      render_error_response(
          :error_location => 'create_twitter_post',
          :error_reason => 'missing required_paramater - request_data',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
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

  def get_slinggit_post_data
    if not params[:offset].blank?
      if not params[:limit].blank?
        search_term = params[:search_term]
        user_name = params[:user_name]

        posts = Post.all(:offset => params[:offset].to_i, :limit => params[:limit].to_i, :order => 'open desc, id desc', :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at')
        posts_array = []
        posts.each do |post|
          posts_array << {
              :post_id => post.id.to_s,
              :open => post.open ? 'true' : 'false',
              :content => post.content,
              :hashtag_prefix => post.hashtag_prefix,
              :price => post.price.to_i,
              :location => post.location,
              :recipient_api_account_ids => post.recipient_api_account_ids.blank? ? '' : post.recipient_api_account_ids,
              :created_at_date => post.created_at.strftime("%m-%d-%Y"),
              :created_at_time => post.created_at.strftime("%H:%M")
          }
        end

        return_data = {
            :rows_found => posts.length.to_s,
            :params_used => {
                :offset => params[:offset],
                :limit => params[:limit],
                :search_term => search_term.blank? ? '' : search_term,
                :user_name => user_name.blank? ? '' : user_name
            },
            :posts => posts_array
        }


        render_success_response(return_data)
      else
        render_error_response(
            :error_location => 'get_slinggit_post_data',
            :error_reason => 'missing required_paramater - limit',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'get_slinggit_post_data',
          :error_reason => 'missing required_paramater - offset',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end


    #order by open, created_at desc
    #start_index required
    #max_records (required)
    #search_term (optional)
    #user_name(optional)
  end

  def get_user_post_data
    #order_by open, created_at desc
    #start_index (required)
    #max_records (required)
    #mobile_auth_token (required)
  end

  def get_user_api_accounts
  end

  def search_posts

  end

  private

  def create_or_update_mobile_auth_token(user_id)
    if mobile_session = MobileSession.first(:conditions => ['user_id = ? AND unique_identifier = ?', user_id, @state])
      mobile_session.update_attribute(:mobile_auth_token, Digest::SHA1.hexdigest("#{Time.now.to_i}-#{user_id}"))
    else
      mobile_session = MobileSession.create(
          :user_id => user_id.to_i,
          :unique_identifier => @state,
          :device_name => @device_name,
          :ip_address => request.blank? ? 'remote_application' : request.remote_ip,
          :mobile_auth_token => Digest::SHA1.hexdigest("#{Time.now.to_i}-#{user_id}"),
          :options => @options
      )
    end
    return mobile_session.mobile_auth_token
  end

  #-----RENDERS-----#

  def render_success_response(options = {})
    render :text => {
        :status => SUCCESS_STATUS,
        :result => options
    }.to_json, :content_type => 'application/json'
  end

  def render_error_response(options = {})
    render :text => {
        :status => ERROR_STATUS,
        :result => options
    }.to_json, :content_type => 'application/json'
  end

  #----BEFORE FILTERS----#

  def set_state
    if params[:state].blank?
      render_error_response(
          :error_location => 'global',
          :error_reason => 'missing required_paramater - state',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
      return
    else
      @state = params[:state]
    end
  end

  def set_device_name
    if params[:device_name].blank?
      render_error_response(
          :error_location => 'global',
          :error_reason => 'missing required_paramater - device_name',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
      return
    else
      @device_name = params[:device_name]
    end
  end

  def set_options
    if params[:options].blank?
      @options = params[:options]
    end
  end

  def require_post
    if not request.post?
      render_error_response(
          :error_location => 'global',
          :error_reason => 'bad request format',
          :error_code => '400',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
      return
    end
  end

  def validate_request_data_is_valid_json
    if not params[:post_data].blank?
      if not params[:post_data].valid_json?
        render_error_response(
            :error_location => 'global',
            :error_reason => 'post_data is not a valid json string',
            :error_code => '400',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    end
  end


end

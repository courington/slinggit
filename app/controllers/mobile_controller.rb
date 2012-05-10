class MobileController < ApplicationController
  before_filter :require_post
  before_filter :validate_request_authenticity
  before_filter :set_state
  before_filter :set_device_name
  before_filter :set_mobile_auth_token, :except => [:user_signup, :user_login]
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
                    :error_reason => 'invalid - email',
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
              :mobile_auth_token => mobile_auth_token,
              :user_name => user.name
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
    if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token])
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
  end

  def user_login_status
    if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token])
      user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => 'name')
      render_success_response(
          :logged_in => true,
          :user_name => user.name
      )
    else
      render_success_response(
          :logged_in => false
      )
    end
  end

  def create_post
    if not params[:hashtag_prefix].blank?
      if not params[:content].blank?
        if not params[:price].blank?
          if not params[:location].blank?
            if mobile_session = MobileSession.first(:conditions => ['mobile_auth_token = ?', @mobile_auth_token], :select => 'user_id')
              if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => ['id'])
                post = Post.new(
                    :user_id => user.id,
                    :hashtag_prefix => params[:hashtag_prefix],
                    :content => params[:content],
                    :price => params[:price],
                    :location => params[:location]
                )

                begin
                  file_name = "#{params[:hashtag_prefix]}_#{post.id}.jpg"
                  image_data = Base64.decode64(request.body.to_s)
                  File.open("public/assets/images/#{file_name}", 'wb') { |file| (file << image_data) }
                rescue Exception => e
                  render_error_response(
                      :error_location => 'fucked_up',
                      :error_reason => "#{e.to_s}",
                      :error_code => "#{request.body.to_s}",
                      :friendly_error => 'Oops, something went wrong.  Please try again later.'
                  )
                  return
                end

                if post.save
                  render_success_response(
                      :post_id => post.id
                  )
                else
                  if post.errors.messages.length > 0
                    error_field = post.errors.messages.first.first
                    error_reason = post.errors.messages.first.last.first
                    render_error_response(
                        :error_location => 'create_post',
                        :error_reason => "#{error_field} #{error_reason}",
                        :error_code => '403',
                        :friendly_error => 'Oops, something went wrong.  Please try again later.'
                    )
                  else
                    render_error_response(
                        :error_location => 'create_post',
                        :error_reason => "unknown error occured",
                        :error_code => '404',
                        :friendly_error => 'Oops, something went wrong.  Please try again later.'
                    )
                  end
                end
              else
                render_error_response(
                    :error_location => 'create_post',
                    :error_reason => 'user not found',
                    :error_code => '404',
                    :friendly_error => 'Oops, something went wrong.  Please try again later.'
                )
              end
            else
              render_error_response(
                  :error_location => 'create_post',
                  :error_reason => 'mobile session not found',
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end
          else
            render_error_response(
                :error_location => 'create_post',
                :error_reason => 'missing required_paramater - location',
                :error_code => '403',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'create_post',
              :error_reason => 'missing required_paramater - price',
              :error_code => '403',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'create_post',
            :error_reason => 'missing required_paramater - content',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'create_post',
          :error_reason => 'missing required_paramater - hashtag_prefix',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def update_post
    @mobile_auth_token
  end

  def get_slinggit_post_data
    if not params[:offset].blank?
      if not params[:limit].blank?
        search_term = params[:search_term]
        user_name = params[:user_name]
        posts = []
        if not user_name.blank?
          if user = User.first(:conditions => ['name = ? AND status != "deleted"', user_name])
            if not search_term.blank?
              posts = Post.all(:conditions => ["(content like ? OR hashtag_prefix like ? OR location like ?) AND user_id = ?", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", user.id], :offset => params[:offset].to_i, :limit => params[:limit].to_i, :order => 'open desc, id desc', :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at')
            else
              posts = Post.all(:conditions => ["user_id = #{user.id}"], :offset => params[:offset].to_i, :limit => params[:limit].to_i, :order => 'open desc, id desc', :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at')
            end
          else
            render_error_response(
                :error_location => 'get_slinggit_post_data',
                :error_reason => "user not found - #{params[:user_name]}",
                :error_code => '404',
                :friendly_error => 'That user no longer has any open items for sale.'
            )
            return
          end
        elsif not search_term.blank?
          posts = Post.all(:conditions => ["content like '%#{search_term}%' OR hashtag_prefix like '%#{search_term}%'"], :offset => params[:offset].to_i, :limit => params[:limit].to_i, :order => 'open desc, id desc', :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at')
        else
          posts = Post.all(:offset => params[:offset].to_i, :limit => params[:limit].to_i, :order => 'open desc, id desc', :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at')
        end

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
              :image_uri => 'http://netobjects.com/assets/images/icon-image-bank.png',
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
  end

  def check_limitations
    if not params[:limitation_type].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token])
        user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => 'id')
        success = passes_limitations?(params[:limitation_type], user.id)
        if success
          render_success_response(
              :limitation_type => params[:limitation_type],
              :pass => true
          )
        else
          render_success_response(
              :limitation_type => params[:limitation_type],
              :pass => false,
              :friendly_error => 'You have reached your 24 hours post limit.  Please contact customer service if you wish to increase this limit.'
          )
        end
      else
        render_error_response(
            :error_location => 'check_limitations',
            :error_reason => 'mobile session not found',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'user_login_status',
          :error_reason => 'missing required_paramater - limitation_type',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  #TODO DOCUMENT
  def resubmit_to_post_recipients
    if not params[:post_id].blank?
      if mobile_session = MobileSession.first(:conditions => ['mobile_auth_token = ?', @mobile_auth_token], :select => 'user_id')
        if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => ['id'])
          if post = Post.first(:conditions => ['id = ? AND user_id = ? AND recipient_api_account_ids IS NOT NULL', params[:post_id], user.id], :select => 'recipient_api_account_ids,id')
            recipient_api_account_ids = post.recipient_api_account_ids.split(',')
            recipient_api_account_ids.each do |api_account_id|
              TwitterPost.create(
                  :user_id => user.id,
                  :api_account_id => api_account_id,
                  :post_id => post.id
              ).do_post
            end
            render_success_response(
                :resubmit_count => recipient_api_account_ids.length
            )
          else
            render_error_response(
                :error_location => 'resubmit_to_post_recipients',
                :error_reason => 'post not found',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'resubmit_to_post_recipients',
              :error_reason => 'user not found',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'resubmit_to_post_recipients',
            :error_reason => 'mobile session not found',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'resubmit_to_post_recipients',
          :error_reason => 'missing required_paramater - post_id',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  #TODO DOCUMENT
  def get_user_api_accounts
    if mobile_session = MobileSession.first(:conditions => ['mobile_auth_token = ?', @mobile_auth_token], :select => 'user_id')
      if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => ['id'])
        api_accounts = ApiAccount.all(:conditions => ['user_id = ? AND status != "deleted"'])

        api_accounts_array = []
        api_accounts.each do |api_account|
          api_accounts_array << {
              :api_id => api_account.api_id.to_s,
              :api_id_hash => api_account.api_id_hash,
              :api_source => api_account.api_source,
              :real_name => api_account.real_name,
              :user_name => api_account.user_name,
              :image_url => api_account.image_url,
              :description => api_account.description,
              :language => api_account.language,
              :location => api_account.location,
              :status => api_account.status,
              :reauth_required => api_account.reauth_required,
              :created_at_date => api_account.created_at.strftime("%m-%d-%Y"),
              :created_at_time => api_account.created_at.strftime("%H:%M")
          }
        end

        return_data = {
            :rows_found => api_accounts.length.to_s,
            :posts => api_accounts_array
        }

        render_success_response(return_data)

      else
        render_error_response(
            :error_location => 'get_user_api_accounts',
            :error_reason => 'user not found',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'get_user_api_accounts',
          :error_reason => 'mobile session not found',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  #TODO IMPLEMENT AND DOCUMENT
  def forgot_password

  end

  #TODO IMPLEMENT AND DOCUMENT
  def reset_password

  end

  #TODO IMPLEMENT AND DOCUMENT
  def active_session_list

  end

  #TODO IMPLEMENT AND DOCUMENT
  def get_active_session_list

  end

  #TODO IMPLEMENT AND DOCUMENT
  def logout_of_active_session

  end

  private

  def create_or_update_mobile_auth_token(user_id)
    if not @state.blank?
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
    else
      render_error_response(
          :error_location => 'global',
          :error_reason => 'missing required_paramater - state validation error',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
      return
    end
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
  def validate_request_authenticity
    if not request.user_agent.downcase.include?("slinggit") or not params[:slinggit_access_token] == Digest::SHA1.hexdigest("chris,dan,phil,chase,duck")
      render_error_response(
          :error_location => 'global',
          :error_reason => 'authentication failed',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
      return
    end
  end

  def set_mobile_auth_token
    if params[:mobile_auth_token].blank?
      render_error_response(
          :error_location => 'global',
          :error_reason => 'missing required_paramater - mobile_auth_token',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
      return
    else
      if MobileSession.exists?(:mobile_auth_token => params[:mobile_auth_token])
        @mobile_auth_token = params[:mobile_auth_token]
      else
        render_error_response(
            :error_location => 'global',
            :error_reason => 'invalid - mobile_auth_token',
            :error_code => '401',
            :friendly_error => 'Your session has expired. Please sign in again.'
        )
        return
      end
    end
  end

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



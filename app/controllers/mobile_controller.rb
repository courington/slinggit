class MobileController < ApplicationController
  before_filter :set_source
  before_filter :require_post, :except => [:add_twitter_account_callback, :finalize_add_twitter_account]
  before_filter :validate_user_agent, :except => [:add_twitter_account, :add_twitter_account_callback, :finalize_add_twitter_account]
  before_filter :validate_request_authenticity, :except => [:add_twitter_account_callback, :finalize_add_twitter_account]
  before_filter :set_state, :except => [:add_twitter_account_callback, :finalize_add_twitter_account]
  before_filter :set_device_name, :except => [:add_twitter_account_callback, :finalize_add_twitter_account]
  before_filter :set_mobile_auth_token, :except => [:user_signup, :user_login, :add_twitter_account, :add_twitter_account_callback, :finalize_add_twitter_account]
  before_filter :set_options, :except => [:add_twitter_account_callback, :finalize_add_twitter_account]
  around_filter :catch_exceptions

  ERROR_STATUS = 'error'
  SUCCESS_STATUS = 'success'
  NATIVE_APP = 'native_app'
  NATIVE_APP_WEB_VIEW = 'native_app_web_view'
  MOBILE_VIEW_ACTIONS = [:add_twitter_account, :add_twitter_account_callback, :finalize_add_twitter_account]
  PLACEHOLDER_IMAGE_STYLES = ['80x80_placeholder', '300x300_placeholder']

  def user_signup
    if not params[:user_name].blank?
      if not params[:email].blank?
        if not params[:password].blank?
          user_name = params[:user_name].downcase
          email = params[:email].downcase
          if not User.exists?(['email = ?', email])
            if not User.exists?(['name = ?', user_name])
              user = User.new(
                  :user_name => params[:user_name],
                  :email => params[:email],
                  :password => params[:password],
                  :password_confirmation => params[:password]
              )

              if user.save
                log_user_login(user)
                mobile_auth_token = create_or_update_mobile_auth_token(user.id)
                if not params[:access_token].blank? and not params[:access_token_secret].blank?
                  client = Twitter::Client.new(oauth_token: params[:access_token], oauth_token_secret: params[:access_token_secret])
                  create_api_account(:source => :twitter, :user_object => user, :api_object => client)
                end
                render_success_response(
                    :mobile_auth_token => mobile_auth_token,
                    :user_id => user.id
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
                  :friendly_error => 'That Username has already been registered.'
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
              :user_name => user.name,
              :user_id => user.id
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
          :user_name => user.name,
          :user_id => user.id
      )
    else
      render_success_response(
          :logged_in => false
      )
    end
  end

  def delete_twitter_account
    if not params[:api_account_id].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token])
        if api_account = ApiAccount.first(:conditions => ['id = ? AND user_id = ?', params[:api_account_id], mobile_session.user_id])
          if not api_account.status == STATUS_DELETED
            success, result = delete_api_account(api_account)
            if success
              render_success_response(
                  :api_account_id => api_account.id,
                  :api_account_status => api_account.status,
                  :new_primary_api_account_id => result.blank? ? '' : result.id,
                  :new_primary_api_account_status => result.blank? ? '' : result.status
              )
            else
              render_error_response(
                  :error_location => 'delete_twitter_account',
                  :error_reason => result,
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end
          else
            render_success_response(
                :api_account_id => api_account.id,
                :api_account_status => api_account.status,
                :note => 'this api account had already been deleted.  There may be a problem with your code.'
            )
          end
        else
          render_error_response(
              :error_location => 'delete_twitter_account',
              :error_reason => 'api account not found',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'delete_twitter_account',
            :error_reason => 'mobile session not found',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'delete_twitter_account',
          :error_reason => 'missing required_paramater - api_account_id',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def add_twitter_account
    setup_twitter_call(url_for :controller => :mobile, :action => :add_twitter_account_callback, :user_name => params[:user_name])
  end

  def add_twitter_account_callback
    rtoken = session['rtoken']
    rsecret = session['rsecret']
    if not params[:denied].blank?
      redirect_to :controller => :mobile, :action => :finalize_add_twitter_account, :result_status => ERROR_STATUS, :friendly_error => 'You can always add your Twitter account later!  For now, all we need is a Slinggit password to get you started.', :error_reason => 'user denied permission'
    else
      request_token = OAuth::RequestToken.new(oauth_consumer, rtoken, rsecret)
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      if not params[:user_name].blank?
        if user = User.first(:conditions => ['name = ?', params[:user_name]])
          client = Twitter::Client.new(oauth_token: access_token.token, oauth_token_secret: access_token.secret)
          create_api_account(:source => :twitter, :user_object => user, :api_object => client)
          redirect_to :controller => :mobile, :action => :finalize_add_twitter_account, :result_status => SUCCESS_STATUS
        else
          redirect_to :controller => :mobile, :action => :finalize_add_twitter_account, :result_status => ERROR_STATUS, :friendly_error => 'Oops, something went wrong.  Please try again later.', :user_name => params[:user_name], :error_reason => 'user not found'
        end
      else
        redirect_to :controller => :mobile, :action => :finalize_add_twitter_account, :result_status => SUCCESS_STATUS, :access_token => access_token.token, :access_token_secret => access_token.secret
      end
    end
  end

  def finalize_add_twitter_account
    #This will never get hit because the mobile page view intercepts it and prevents it from redirecting here.
    #It is not necessary for this to contain an attached view or render any thing what so ever
    #It is however, necessary for this definition to be present for rails url_for routing purposes and so that we have a distinct url that
    #indicates to the mobile device that the call is over.
  end

  def create_post
    if not params[:hashtag_prefix].blank?
      if not params[:content].blank?
        if not params[:price].blank?
          if not params[:location].blank?
            if mobile_session = MobileSession.first(:conditions => ['mobile_auth_token = ?', @mobile_auth_token], :select => 'user_id')
              if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => ['id'])

                tmp_file_path = get_temp_photo_path(params[:hashtag_prefix] + Time.now.to_f.to_s)
                if not params[:image_data].blank?
                  image_data = Base64.decode64(params[:image_data])
                  @file = File.open(tmp_file_path, 'wb') { |file| (file << image_data) }
                end

                post = Post.new(
                    :user_id => user.id,
                    :hashtag_prefix => params[:hashtag_prefix],
                    :content => params[:content],
                    :price => params[:price],
                    :location => params[:location],
                    :photo => @file
                )

                #if not post.has_photo?
                #  File.delete(tmp_file_path)
                #end

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

  def get_slinggit_post_data
    if not params[:offset].blank?
      if not params[:limit].blank?

        #offset can be 0
        offset = params[:offset].to_i
        offset = 0 if offset < 0

        #limit cannot be 0
        limit = params[:limit].to_i
        limit = 1 if limit <= 0

        #starting_post_id can come in as 0 or blank and needs to be set to the max + 1 if thats the case
        starting_post_id = params[:starting_post_id]
        starting_post_id = Post.count() + 1 if (starting_post_id.blank? or starting_post_id.to_i <= 0)
        starting_post_id = starting_post_id.to_i

        posts = []
        success = false
        result = {}

        filter_data = {
            :offset => offset,
            :limit => limit,
            :starting_post_id => starting_post_id,
            :search_term => params[:search_term],
            :user_name => params[:user_name]
        }

        if not filter_data[:user_name].blank?
          success, result = get_slinggit_post_data_for_user(filter_data)
        else
          success, result = get_all_slinggit_post_data(filter_data)
        end

        if success
          posts_array = []
          result.each do |post|
            posts_array << {
                :post_id => post.id,
                :user_id => post.user_id,
                :open => post.open ? 'true' : 'false',
                :content => post.content,
                :hashtag_prefix => post.hashtag_prefix,
                :price => post.price.to_i,
                :location => post.location,
                :recipient_api_account_ids => post.recipient_api_account_ids.blank? ? '' : post.recipient_api_account_ids,
                :image_uri => post.has_photo? ? "#{BASEURL}/#{post.photo.url(:search)}" : nil,
                :created_at_date => post.created_at.strftime("%m-%d-%Y"),
                :created_at_time => post.created_at.strftime("%H:%M")
            }
          end

          return_data = {
              :rows_found => result.length.to_s,
              :filters_used => filter_data,
              :posts => posts_array
          }

          render_success_response(return_data)
        else
          render_error_response(result)
        end
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

  def get_single_slinggit_post_data
    if not params[:post_id].blank?
      if post = Post.first(:conditions => ['id = ? and status = ?', params[:post_id], STATUS_ACTIVE])
        comments_array = []
        post.comments.each do |comment|
          if comment.status == STATUS_ACTIVE
            comments_array << comment.attributes.merge!(
                :user_name => comment.user.name,
                :created_at_date => comment.created_at.strftime("%m-%d-%Y"),
                :created_at_time => comment.created_at.strftime("%H:%M")
            )
          end
        end

        render_success_response(
            post.attributes.merge!(:comments => comments_array)
        )
      else
        render_error_response(
            :error_location => 'get_individual_slinggit_post_data',
            :error_reason => 'not found - post',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'get_individual_slinggit_post_data',
          :error_reason => 'missing required_paramater - post_id',
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

  def get_user_api_accounts
    if mobile_session = MobileSession.first(:conditions => ['mobile_auth_token = ?', @mobile_auth_token], :select => 'user_id')
      if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => ['id'])
        api_accounts = ApiAccount.all(:conditions => ['user_id = ? AND status != ?', user.id, STATUS_DELETED])

        api_accounts_array = []
        api_accounts.each do |api_account|
          api_accounts_array << {
              :id => api_account.id.to_s,
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
            :api_accounts => api_accounts_array
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

  def password_reset
    @email_or_username = params[:email_or_username]
    if not @email_or_username.blank?
      if user = User.first(:conditions => ['email = ? or name = ?', @email_or_username.downcase, @email_or_username.downcase], :select => 'id,email,password_reset_code,name')
        if user.password_reset_code.blank?
          user.update_attribute(:password_reset_code, Digest::SHA1.hexdigest("#{rand(999999)}-#{Time.now}-#{@email}"))
        end
        UserMailer.password_reset(user).deliver
        render_success_response(
            :email_sent_to => user.email,
            :password_reset_code => user.password_reset_code
        )
      else
        render_error_response(
            :error_location => 'password_reset',
            :error_reason => 'not found - user',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'password_reset',
          :error_reason => 'missing required_paramater - email_or_username',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def create_post_comment
    if not params[:post_id].blank?
      if not params[:comment_body].blank?
        if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
          if post = Post.first(:conditions => ['id = ? and status = ?', params[:post_id], STATUS_ACTIVE])
            comment = Comment.create(
                :post_id => params[:post_id],
                :user_id => mobile_session.user_id,
                :body => params[:comment_body]
            )
            render_success_response(
                :comment_id => comment.id
            )
          else
            render_error_response(
                :error_location => 'create_post_comment',
                :error_reason => 'not found - post',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'create_post_comment',
              :error_reason => 'not found - mobile_session',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'create_post_comment',
            :error_reason => 'missing required_paramater - comment_body',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'create_post_comment',
          :error_reason => 'missing required_paramater - post_id',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def delete_post_comment
    if not params[:post_id].blank?
      if not params[:comment_id].blank?
        if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
          if post = Post.first(:conditions => ['id = ? and user_id = ?', params[:post_id], mobile_session.user_id])
            if comment = Comment.first(:conditions => ['post_id = ? and id = ?', mobile_session.user_id, params[:comment_id]])
              comment.update_attribute(:status, STATUS_DELETED)
              render_success_response(
                  :comment_id => comment.id,
                  :status => comment.status
              )
            else
              render_error_response(
                  :error_location => 'delete_post_comment',
                  :error_reason => 'not found - comment for owner',
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end
          else
            render_error_response(
                :error_location => 'delete_post_comment',
                :error_reason => 'not found - post',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'delete_post_comment',
              :error_reason => 'not found - mobile_session',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'delete_post_comment',
            :error_reason => 'missing required_paramater - comment_id',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'delete_post_comment',
          :error_reason => 'missing required_paramater - post_id',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def get_messages
    if not params[:offset].blank?
      if not params[:limit].blank?
        if mobile_session = MobileSession.first(:conditions => ['mobile_auth_token = ?', @mobile_auth_token], :select => 'user_id')
          if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => ['id'])
            #offset can be 0
            offset = params[:offset].to_i
            offset = 0 if offset < 0

            #limit cannot be 0
            limit = params[:limit].to_i
            limit = 1 if limit <= 0

            #starting_message_id can come in as 0 or blank and needs to be set to the max + 1 if thats the case
            starting_message_id = params[:starting_message_id]
            starting_message_id = Message.count() + 1 if (starting_message_id.blank? or starting_post_id.to_i <= 0)
            starting_message_id = starting_message_id.to_i

            messages = Message.all(:conditions => ['recipient_user_id = ? AND status != ? AND id <= ?', user.id, STATUS_DELETED, starting_message_id], :order => 'created_at desc, status desc', :limit => limit, :offset => offset, :select => 'creator_user_id, recipient_user_id,source,source_id,contact_info_json,body,status,created_at')

            render_success_response(
                :rows_found => messages.length,
                :filters_used => {:offset => offset, :limit => limit, :starting_message_id => starting_message_id},
                :messages => messages.map { |m|
                  source_object = m.source_object(:table => 'Post', :columns => 'status,hashtag_prefix,content')
                  source_object_attributes = nil
                  source_object_attributes = source_object.attributes if not source_object.blank?
                  m.attributes.merge(
                      :created_at_time => m.created_at.strftime("%H:%M"),
                      :created_at_date => m.created_at.strftime("%m-%d-%Y"),
                      :source_object_data => source_object_attributes
                  )
                }
            )
          else
            render_error_response(
                :error_location => 'get_messages',
                :error_reason => 'user not found',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'get_messages',
              :error_reason => 'mobile session not found',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'get_messages',
            :error_reason => 'missing required_paramater - limit',
            :error_code => '403',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'get_messages',
          :error_reason => 'missing required_paramater - offset',
          :error_code => '403',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def delete_post
    if not params[:post_id].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
        if post = Post.first(:conditions => ['id = ? and user_id = ?', params[:post_id], mobile_session.user_id], :select => 'id,status')
          post.update_attribute(:status, STATUS_DELETED)
          render_success_response(
              :post_id => post.id,
              :status => post.status
          )
        else
          render_error_response(
              :error_location => 'delete_post',
              :error_reason => 'not found - post',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'delete_post',
            :error_reason => 'not found - mobile_session',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'delete_post',
          :error_reason => 'missing required_paramater - post_id',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def get_post_image
    if not params[:image_style].blank?

      #check to see if app is requesting the placeholder image and return it
      #the app could technically just grab the image with its name, however, if we move it or decide to change the name, this will allow more flexibility
      if PLACEHOLDER_IMAGE_STYLES.include? params[:image_style]
        if File.exists? "#{Rails.root}/app/assets/images/#{params[:image_style]}.png"
          render_success_response(
              :post_id => post.id,
              :place_holder => true,
              :image_uri => "#{BASEURL}/assets/#{params[:image_style]}.png"
          ) and return
        else
          render_error_response(
              :error_location => 'get_post_image',
              :error_reason => 'place holder image file does not exist on the server',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          ) and return
        end
      end

      if not params[:post_id].blank?
        if post = Post.first(:conditions => ['id = ?', params[:post_id]], :select => 'id,photo_file_name,photo_content_type,photo_file_size,photo_updated_at,status')
          if not post.status == STATUS_DELETED
            if post.has_photo?
              render_success_response(
                  :post_id => post.id,
                  :place_holder => false,
                  :image_uri => "#{BASEURL}/#{post.photo.url(params[:image_style].to_sym)}"
              )
            else
              render_error_response(
                  :error_location => 'get_post_image',
                  :error_reason => 'post does not contain a photo',
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end
          else
            render_error_response(
                :error_location => 'get_post_image',
                :error_reason => 'post has been deleted',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'get_post_image',
              :error_reason => 'not found - post',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end


      else
        render_error_response(
            :error_location => 'get_post_image',
            :error_reason => 'missing required_paramater - post_id',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'get_post_image',
          :error_reason => 'missing required_paramater - image_style',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def send_message
    if not params[:recipient_user_id].blank?
      if not params[:body].blank?
        if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
          if recipient = User.first(:conditions => ['id = ? AND status != ?', params[:recipient_user_id].to_i, STATUS_DELETED], :select => 'email')
            message = Message.new(
                :send_email => true,
                :creator_user_id => mobile_session.user_id,
                :recipient_user_id => params[:recipient_user_id].to_i,
                :contact_in_json => recipient.email,
                :body => params[:body]
            )

            if not params[:post_id].blank?
              if Post.exists?(['id = ?', params[:post_id]])
                message.source = 'post'
                message.source_id = params[:post_id].to_i
              end
            end

            if message.save
              render_success_response(
                  :message_id => message.id,
                  :email_sent => true
              )
            else
              render_error_response(
                  :error_location => 'send_message',
                  :error_reason => message.errors.messages,
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end

          else
            render_error_response(
                :error_location => 'send_message',
                :error_reason => 'recipient user object was either not found or has been deleted',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'send_message',
              :error_reason => 'not found - mobile_session',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'send_message',
            :error_reason => 'missing required_paramater - body',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'send_message',
          :error_reason => 'missing required_paramater - recipient_user_id',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def delete_message
    if not params[:message_ids].blank?
      if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')

        messages_deleted = 0
        messages_not_deleted = 0

        #grabbing all messages before verifying owner such that if for some reason its a mixed bag I can report back to the app that some were deleted and others werent so we can fix the problem.
        messages = Message.all(:conditions => ['id in (?)', params[:message_ids].join(',')], :select => 'id,user_id,status')
        messages.each do |message|
          if message.recipient_user_id == mobile_session.user_id
            message.update_attribute(:status, STATUS_DELETED)
            messages_deleted += 1
          else
            messages_not_deleted += 1
          end
        end

        render_success_response(
            :message_ids => params[:message_ids],
            :logged_in_user_id => mobile_session.user_id,
            :rows_found => messages.length,
            :messages_deleted => messages_deleted,
            :messages_not_deleted => messages_not_deleted,
            :note => 'Messages not deleted should never be greater than 0.  If it is greater than 0, that means message ids are being passed in that dont belong to the logged in user'
        )
      else
        render_error_response(
            :error_location => 'delete_message',
            :error_reason => 'not found - mobile_session',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'delete_message',
          :error_reason => 'missing required_paramater - message_ids',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

#TODO SEND EMAIL TO INFORM OF PASSWORD CHANGE
  def change_password
    if not params[:old_password].blank?
      if not params[:new_password].blank?
        if params[:new_password].length >= 6
          if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
            if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => 'id,password')
              if user.authenticate(params[:old_password])
                user.password = params[:new_password]
                user.password_confirmation = params[:new_password]
                if user.save
                  render_success_response(
                      :password_changed => true,
                      :logged_in_user_id => mobile_session.user_id
                  )
                else
                  render_error_response(
                      :error_location => 'change_password',
                      :error_reason => user.errors.messages,
                      :error_code => '404',
                      :friendly_error => 'Oops, something went wrong.  Please try again later.'
                  )
                end
              else
                render_error_response(
                    :error_location => 'change_password',
                    :error_reason => 'authentication with old password failed',
                    :error_code => '401',
                    :friendly_error => 'Current password is incorrect'
                )
              end
            else
              render_error_response(
                  :error_location => 'change_password',
                  :error_reason => 'not found - user',
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end
          else
            render_error_response(
                :error_location => 'change_password',
                :error_reason => 'not found - mobile_session',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'change_password',
              :error_reason => 'password is too short',
              :error_code => '401',
              :friendly_error => 'New password needs to be at least 6 characters.'
          )
        end
      else
        render_error_response(
            :error_location => 'change_password',
            :error_reason => 'missing required_paramater - new_password',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'change_password',
          :error_reason => 'missing required_paramater - old_password',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

#TODO SEND EMAIL TO VERIFY NEW EMAIL
  def change_email
    if not params[:new_email].blank?
      if params[:new_email] =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        if mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
          if user = User.first(:conditions => ['id = ?', mobile_session.user_id], :select => 'id,email')
            user.email = params[:new_email]
            user.status = STATUS_UNVERIFIED
            if user.save
              render_success_response(
                  :email_changed => true,
                  :new_email => params[:new_email],
                  :user_status => STATUS_UNVERIFIED,
                  :logged_in_user_id => mobile_session.user_id
              )
            else
              render_error_response(
                  :error_location => 'change_email',
                  :error_reason => user.errors.messages,
                  :error_code => '404',
                  :friendly_error => 'Oops, something went wrong.  Please try again later.'
              )
            end
          else
            render_error_response(
                :error_location => 'change_email',
                :error_reason => 'not found - user',
                :error_code => '404',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'change_email',
              :error_reason => 'not found - mobile_session',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'change_email',
            :error_reason => 'new email address is not a valid format',
            :error_code => '404',
            :friendly_error => 'The email address entered is not valid.'
        )
      end
    else
      render_error_response(
          :error_location => 'change_email',
          :error_reason => 'missing required_paramater - new_email',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def get_active_sessions
    if current_mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
      mobile_sessions = MobileSession.all(:conditions => ['user_id = ? AND id != ?', current_mobile_session.user_id, current_mobile_session.id], :select => 'id,user_id,unique_identifier,device,_name,id_address,created_at', :order => 'created_at desc')
      if mobile_sessions.length > 0
        render_success_response(
            :rows_found => mobile_sessions.length,
            :logged_in_user_id => current_mobile_session.user_id,
            :mobile_sessions => mobile_sessions.map { |ms|
              ms.attributes.merge(
                  :created_at_time => ms.created_at.strftime("%H:%M"),
                  :created_at_date => ms.created_at.strftime("%m-%d-%Y")
              )
            }
        )
      else
        render_success_response(
            :rows_found => mobile_sessions.length,
            :logged_in_user_id => current_mobile_session.user_id,
            :mobile_sessions => nil
        )
      end
    else
      render_error_response(
          :error_location => 'get_active_sessions',
          :error_reason => 'not found - mobile_session',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

  def delete_active_session
    if not params[:session_id].blank?
      if current_mobile_session = MobileSession.first(:conditions => ['unique_identifier = ? AND mobile_auth_token = ?', @state, @mobile_auth_token], :select => 'id,user_id')
        if session_to_delete = MobileSession.first(:conditions => ['id = ? AND user_id = ?', params[:session_id], current_mobile_session.user_id], :select => 'id')
          if session_to_delete.destroy
            render_success_response(
                :logged_in_user_id => current_mobile_session.user_id,
                :session_deleted => true
            )
          else
            render_error_response(
                :error_location => 'delete_active_session',
                :error_reason => 'unablet to delete session',
                :error_code => '401',
                :friendly_error => 'Oops, something went wrong.  Please try again later.'
            )
          end
        else
          render_error_response(
              :error_location => 'delete_active_session',
              :error_reason => 'not found - session_to_delete',
              :error_code => '404',
              :friendly_error => 'Oops, something went wrong.  Please try again later.'
          )
        end
      else
        render_error_response(
            :error_location => 'delete_active_session',
            :error_reason => 'not found - mobile_session',
            :error_code => '404',
            :friendly_error => 'Oops, something went wrong.  Please try again later.'
        )
      end
    else
      render_error_response(
          :error_location => 'delete_active_session',
          :error_reason => 'not found - session_id',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

#TODO IMPLEMENT
  def report_abuse

  end

  private

  def get_all_slinggit_post_data(filter_data)
    matches = []
    if not filter_data[:search_term].blank?
      matches = Post.all(:conditions => ["open = ? AND id <= ? AND(content like ? OR hashtag_prefix like ? OR location like ?)", true, filter_data[:starting_post_id], "%#{filter_data[:search_term]}%", "%#{filter_data[:search_term]}%", "%#{filter_data[:search_term]}%"], :order => 'created_at desc', :limit => filter_data[:limit].to_i, :offset => filter_data[:offset], :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at,photo_file_name,photo_content_type,photo_file_size,photo_updated_at,user_id')
    else
      matches = Post.all(:conditions => ["open = ? AND id <= ?", true, filter_data[:starting_post_id]], :order => 'created_at desc', :limit => filter_data[:limit], :offset => filter_data[:offset], :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at,photo_file_name,photo_content_type,photo_file_size,photo_updated_at,user_id')
    end
    return [true, matches]
  end

  def get_slinggit_post_data_for_user(filter_data)
    matches = []
    if user = User.first(:conditions => ['name = ? AND status != ?', filter_data[:user_name], STATUS_DELETED], :select => 'id')
      if not filter_data[:search_term].blank?
        matches = Post.all(:conditions => ["user_id = ? AND open = ? AND id <= ? AND (content like ? OR hashtag_prefix like ? OR location like ?)", user.id, true, filter_data[:starting_post_id], "%#{filter_data[:search_term]}%", "%#{filter_data[:search_term]}%", "%#{filter_data[:search_term]}%"], :order => 'created_at desc', :limit => filter_data[:limit].to_i, :offset => filter_data[:offset], :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at,photo_file_name,photo_content_type,photo_file_size,photo_updated_at,user_id')
      else
        matches = Post.all(:conditions => ["user_id = ? AND open = ? AND id <= ?", user.id, true, filter_data[:starting_post_id]], :order => 'created_at desc', :limit => filter_data[:limit], :offset => filter_data[:offset], :select => 'id,content,hashtag_prefix,price,open,location,recipient_api_account_ids,created_at,photo_file_name,photo_content_type,photo_file_size,photo_updated_at,user_id')
      end
      return [true, matches]
    else
      error_hash = {
          :error_location => 'get_slinggit_post_data',
          :error_reason => 'user not found',
          :error_code => '404',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'}
      return [false, error_hash]
    end
  end

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
    if not params[:slinggit_access_token] == SLINGGIT_SECRET_HASH
      render_error_response(
          :error_location => 'global',
          :error_reason => 'authentication failed',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.',
          :user_agent => request.user_agent
      )
      return
    end
  end

  def validate_user_agent
    if not request.user_agent.downcase.include?("slinggit")
      render_error_response(
          :error_location => 'global',
          :error_reason => 'authentication failed - invalid user_agent',
          :error_code => '401',
          :friendly_error => 'Oops, something went wrong.  Please try again later.',
          :user_agent => request.user_agent
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

  def set_source
    if MOBILE_VIEW_ACTIONS.include? params[:action].to_sym
      session[:source] = NATIVE_APP_WEB_VIEW
    else
      session[:source] = NATIVE_APP
    end
  end

  def get_temp_photo_path(name)
    "#{Rails.root}/public/tmp_images/#{name}.jpg"
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

  def catch_exceptions
    yield
  rescue => exception
    create_problem_report(exception)
    if session[:source] and session[:source] == NATIVE_APP_WEB_VIEW
      redirect_to :action => :finalize_add_twitter_account, :result_status => ERROR_STATUS, :friendly_error => 'Oops, something went wrong.  Please try again later.', :error_reason => exception.to_s
    else
      render_error_response(
          :error_location => 'global',
          :error_reason => "exception caught: #{exception.message} - #{exception.backtrace}",
          :error_code => '500',
          :friendly_error => 'Oops, something went wrong.  Please try again later.'
      )
    end
  end

end

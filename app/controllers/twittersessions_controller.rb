class TwittersessionsController < ApplicationController

  def new
  end

  def signin
    setup_twitter_call
  end

  def create
    setup_twitter_call
  end

  def callback
    if not params[:denied].blank?
      reset_twitter_session_and_cookies
      redirect_to new_user_path
    else
      request_token = OAuth::RequestToken.new(oauth_consumer, session['rtoken'], session['rsecret'])
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      reset_session
      session['access_token'] = access_token.token
      session['access_secret'] = access_token.secret
      if cookies[:twitter_user_name].blank? or cookies[:twitter_user_email].blank?
        redirect_to edit_user_path(current_user)
      else
        redirect_to new_user_path
      end
    end
  end

end
class TwittersessionsController < ApplicationController

  def new
  end

  def create
    setup_twitter_call
  end

  def callback
    if not params[:denied].blank?
      flash[:success] = "You can always add your twitter account later!"
      redirect_to edit_user_path(current_user)
    else
      request_token = OAuth::RequestToken.new(oauth_consumer, session['rtoken'], session['rsecret'])
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      reset_session
      session['access_token'] = access_token.token
      session['access_secret'] = access_token.secret
      redirect_to new_user_path
    end
  end

  # this is the redirect for reauthorization
  def reauthorize
  end

  # form action
  def create_reauthorization
    setup_twitter_call(url_for(controller: :twittersessions, action: :reauthorize_callback, email: current_user.email))
  end

  # reauth callback
  def reauthorize_callback
    request_token = OAuth::RequestToken.new(oauth_consumer, session['rtoken'], session['rsecret'])
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    if not params[:email].blank?
      user = User.find_by_email(params[:email])
      if not user.blank?
        client = Twitter::Client.new(oauth_token: access_token.token, oauth_token_secret: access_token.secret)
        update_api_account(:source => :twitter, :user_object => user, :api_object => client)
      end
    end
    redirect_to current_user
  end

end
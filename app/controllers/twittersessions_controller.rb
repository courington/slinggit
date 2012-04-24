class TwittersessionsController < ApplicationController

  def new
  end
  
  def create
    request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
    session['rtoken'] = request_token.token
    session['rsecret'] = request_token.secret
    redirect_to request_token.authorize_url
  end  

  def callback
    request_token = OAuth::RequestToken.new(oauth_consumer, session['rtoken'], session['rsecret'])
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    reset_session
    session['access_token'] = access_token.token
    session['access_secret'] = access_token.secret
    redirect_to edit_user_path(current_user)
  end  

  private

    def oauth_consumer
      @oauth_consumer ||= OAuth::Consumer.new(Twitter.consumer_key, Twitter.consumer_secret, :site => 'http://api.twitter.com', :request_endpoint => 'http://api.twitter.com', :sign_in => true)
    end

end
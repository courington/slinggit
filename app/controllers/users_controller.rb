class UsersController < ApplicationController
  before_filter :signed_in_user, only: [:edit, :update]
  before_filter :correct_user, only: [:edit, :update]
  before_filter :admin_user, only: [:index, :destroy]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.first(:conditions => ['id = ?', params[:id]])
    if not @user.blank?
      @posts = @user.posts.paginate(page: params[:page])
    else
      if signed_in?
        redirect_to current_user
      else
        redirect_to new_user_path
      end
    end
  end

  def new
    if session[:user].blank?
      @user = User.new
      # CMK: storing return_url here, prior to session reset, so that we can return
      # the use back to, say, a post if it's not nil.
      return_url = session[:return_to]
      reset_session
      if return_url
        session[:return_to] = return_url
      end
    else
      @user = session[:user]
      session.delete(:user)
    end
  end

  def create
    @user = User.new(params[:user])
    if not params[:twitter_authenticate].blank?
      success = validate_pre_twitter_data
      if success
        # CMK: so I added :return_url to parameters, so that we can have that after
        # twitter authentication, in order to redirect the use back to, say, a post.
        setup_twitter_call(url_for(:controller => :users, :action => :twitter_signup_callback, :name => @user.name, :email => @user.email, :return_url => session[:return_to]))
      else
        render 'new'
      end
    else
      if @user.save
        if not session['access_token'].blank? and not session['access_secret'].blank?
          client = Twitter::Client.new(oauth_token: session['access_token'], oauth_token_secret: session['access_secret'])
          create_api_account(:source => :twitter, :user_object => @user, :api_object => client)
          session.delete('access_token')
          session.delete('access_secret')
        end
        UserMailer.welcome_email(@user).deliver
        sign_in @user
        flash[:success] = "Welcome SlingGit.  Time to start slingin!"
        redirect_back_or @user
      else
        render 'new'
      end
    end
  end

  def edit
  end

  def update
    # @user = User.find(params[:id])  !Not needed because of :correct_user before_filter
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated"
      sign_in @user
      reset_session
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    user = User.first(:conditions => ['id = ?', params[:id]])
    if user
      user.status = 'deleted'
      flash[:success] = "User destroyed."
    end
    redirect_to users_path
  end

  def password_reset
    #using password_reset instead of forgot_password becuase I feel like the url forgot_password frustrates people or makes them feel dumb.
    @email_or_username = params[:email_or_username]
    if request.post?
      if not @email_or_username.blank?
        if user = User.first(:conditions => ['email = ? or name = ?', @email_or_username.downcase, @email_or_username.downcase], :select => 'id,email,password_reset_code,name')
          if user.password_reset_code.blank?
            user.update_attribute(:password_reset_code, Digest::SHA1.hexdigest("#{rand(999999)}-#{Time.now}-#{@email}"))
          end
          UserMailer.password_reset(user).deliver
          flash.now[:success] = "Password reset instructions have been sent to '#{user.email}'."
        else
          flash.now[:error] = "That email address or username doesn't have a registered user account. Are you sure you've signed up?"
        end
      else
        flash.now[:error] = "We need either an email address, or a username, so we know who to send instructions to."
      end
    end
  end

  def enter_new_password
    #linked to from the forgot password email... id in this case is the password_reset_code in the users table
    @password_reset_code = params[:id] if not params[:id].blank?

    if not @password_reset_code.blank?
      @user = User.first(:conditions => ['password_reset_code = ?', @password_reset_code])
      if @user.blank?
        flash[:error] = 'That password reset code is invalid.'
        redirect_to :controller => :sessions, :action => :new
      else
        if request.post?
          @user.password = params[:password]
          @user.password_confirmation = params[:password_confirmation]
          @user.password_reset_code = nil
          if @user.save
            sign_in @user
            flash[:success] = "Your password has been reset."
            redirect_to @user
          end
        end
      end
    else
      flash[:error] = "Oops, that link didn't contain all the information we needed to reset your password."
      redirect_to :controller => :sessions, :action => :new
    end
  end

  def twitter_signup_callback
    rtoken = session['rtoken']
    rsecret = session['rsecret']

    reset_session #start new

    if not params[:name].blank? and not params[:email].blank?
      session[:user] = User.new(
          :name => params[:name],
          :email => params[:email]
      )
    end
    if not params[:denied].blank?
      flash[:success] = "You can always add your Twitter account later!  For now, all we need is a Slinggit password to get you started."
      session[:no_thanks] = true
      # CMK: storing return url so that we can return a user to a post if he was to signin there
      session[:return_to] = params[:return_url]
      redirect_to new_user_path
    else
      request_token = OAuth::RequestToken.new(oauth_consumer, rtoken, rsecret)
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      session['access_token'] = access_token.token
      session['access_secret'] = access_token.secret
      session[:twitter_permission_granted] = true
      # CMK: storing return url so that we can return a user to a post if he was to signin there
      session[:return_to] = params[:return_url]
      flash[:success] = "Your Twitter account has been authorized.  One last step, please provide a Slinggit password."
      redirect_to new_user_path
    end
  end

  def set_no_thanks
    session[:no_thanks] = true
    render :text => '', :status => 200
  end

  def reset_page_session
    session.delete(:twitter_permission_granted)
    session.delete(:no_thanks)
    render :text => '', :status => 200
  end

  def verify_email_availability
    if request.post?
      if User.exists?(:email => params[:email])
        render :text => 'unavailable', :status => 200
      else
        render :text => 'available', :status => 200
      end
    end
  end

  def verify_username_availability
    if request.post?
      if User.exists?(:name => params[:name])
        render :text => 'unavailable', :status => 200
      else
        render :text => 'available', :status => 200
      end  
    end  
  end

  private

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_path) unless current_user?(@user)
  end

  def admin_user
    redirect_to(root_path) unless not current_user.blank? and current_user.admin?
  end

  def validate_pre_twitter_data
    #This validates all possible errors for username and email after the user clicks authenticate with twitter
    #on the sign up page

    if params[:user][:name].blank?
      @user.errors.messages[:name] = ["can't be blank"]
    else
      if not params[:user][:name] =~ /\A[a-z0-9_-]{,20}\z/i
        @user.errors.messages[:name] = ["can only contain letters, numbers, underscores and dashes and cannot be more than 20 characters."]
      else
        if User.exists?(:name => params[:user][:name])
          @user.errors.messages[:name] = ["has already been registered"]
        end
      end
    end

    if params[:user][:email].blank?
      @user.errors.messages[:email] = ["can't be blank"]
    else
      if not params[:user][:email] =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        @user.errors.messages[:email] = ["is invalid"]
      else
        if User.exists?(:email => params[:user][:email])
          @user.errors.messages[:email] = ["has already been registered"]
        end
      end
    end

    if @user.errors.messages.blank?
      return true
    else
      return false
    end
  end

end

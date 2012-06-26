class MessagesController < ApplicationController
  before_filter :signed_in_user, :except => [:new, :create]
  before_filter :user_verified, only: [:index, :show, :new, :create, :delete, :reply]

  def index
    @messages = Message.paginate(page: params[:page], :per_page => 10, :conditions => ['recipient_user_id = ? AND status != ?', current_user.id, STATUS_DELETED], :order => 'id desc, status desc')
    @unread = Message.count(:conditions => ['recipient_user_id = ? AND status = ?', current_user.id, STATUS_UNREAD])
  end

  def show
    if not params[:id].blank?
      if @message = Message.first(:conditions => ['id_hash = ? AND recipient_user_id = ?', params[:id], current_user.id], :select => 'id,status,body,created_at,id_hash,contact_info_json,creator_user_id')
        @message.update_attribute(:status, STATUS_READ)
      else
        flash[:error] = "Message not found"
      end
    end
  end

  def reply
    @message ||= Message.new

    if not params[:id].blank?
      session.delete(:parent_message)
      if parent_message = Message.first(:conditions => ['id_hash = ? and recipient_user_id = ? AND status != ?', params[:id], current_user.id, STATUS_DELETED])
        @parent_message = parent_message
        session[:parent_message_id_hash] = parent_message.id_hash
      end
    elsif not session[:parent_message_id_hash].blank?
      if parent_message = Message.first(:conditions => ['id_hash = ? and recipient_user_id = ? AND status != ?', session[:parent_message_id_hash], current_user.id, STATUS_DELETED])
        @parent_message = parent_message
      else
        #TODO redirect to report an issue
        flash[:error] = 'You appear to be doing something we are not familiar with.  Please let us know what it is you were trying to do.'
        redirect_to root_path
      end
    else
      flash[:error] = "Sorry, we couldn't find the message you were trying to reply to."
      redirect_to message_path
    end
  end

  def new
    @message ||= Message.new

    #if they hit this account we know they arent replying
    session.delete(:parent_message_id_hash)

    #this is used to populate what they had entered before we detected that the email address they entered was already registered.  (not signed in user))
    if not session[:message_data_before_login].blank?
      @email_entered = session[:message_data_before_login][:email]
      @message_entered = session[:message_data_before_login][:body]
      session.delete(:message_data_before_login)
    end

    if not params[:id].blank?
      session.delete(:message_post_id_hash)
      if post = Post.first(:conditions => ['id_hash = ? AND status != ? AND open = ?', params[:id], [STATUS_DELETED], true])
        if not signed_in? or (signed_in? and not post.user_id == current_user.id)
          @post = post
          session[:message_post_id_hash] = post.id_hash
        else
          flash[:error] = "I'm gonna take a shot in the dark here and assume you didn't really want to send a message to your self."
          redirect_to current_user and return
        end
      end
    elsif not session[:message_post_id_hash].blank?
      if post = Post.first(:conditions => ['id_hash = ? AND status != ? AND open = ?', session[:message_post_id_hash], [STATUS_DELETED], true])
        @post = post
      else
        #TODO redirect to report an issue
        flash[:error] = 'You appear to be doing something we are not familiar with.  Please let us know what it is you were trying to do.'
        redirect_to root_path
      end
    else
      flash[:error] = 'Sad news, the post you are trying to reply to has either been closed or deleted.'
      redirect_to root_path and return
    end
  end

  def create
    if request.post?
      if session[:parent_message_id_hash]
        if params[:message]
          parent_message = Message.first(:conditions => ['id_hash = ? and recipient_user_id = ? AND status != ?', session[:parent_message_id_hash], current_user.id, STATUS_DELETED])
          @message = Message.new(params[:message])
          @message.creator_user_id = current_user.id
          @message.recipient_user_id = parent_message.creator_user_id
          @message.source = parent_message.source
          @message.source_id = parent_message.source_id
          @message.contact_info_json = current_user.email
          @message.parent_source_id = parent_message.id
          @message.send_email = true

          if @message.save
            flash[:success] = "Message has been sent."
            session.delete(:parent_message_id_hash)
            redirect_to :controller => :messages, :action => :index
          else
            @parent_message = parent_message
            @message = Message.new(params[:message])
            render 'reply'
          end
        else
          #TODO redirect to report an issue
          flash[:error] = 'You appear to be doing something we are not familiar with.  Please let us know what it is you were trying to do.'
          redirect_to root_path
        end
      else
        if session[:message_post_id_hash]
          if params[:message]
            message_post = Post.first(:conditions => ['id_hash = ? AND status != ? AND open = ?', session[:message_post_id_hash], [STATUS_DELETED], true])
            @message = Message.new(params[:message])
            if signed_in?
              @message.contact_info_json = current_user.email
            elsif not @message.contact_info_json.blank?
              #the above if elsif statment is invalid once we start collecting additional contect info
              #this will need to rip the email field out first then validate it.
              if user = User.first(:conditions => ['email = ?', @message.contact_info_json], :select => 'email')
                flash[:notice] = "The email you provided belongs to a registered Slinggit user.  Please sign in first."
                session[:return_to] = url_for :controller => :messages, :action => :new, :id => message_post.id_hash
                session[:message_data_before_login] = {:email => @message.contact_info_json, :body => @message.body}
                redirect_to :controller => :sessions, :action => :new, :email => user.email and return
              end
            end

            @message.creator_user_id = signed_in? ? current_user.id : nil
            @message.recipient_user_id = message_post.user_id
            @message.source = 'post'
            @message.source_id = message_post.id
            @message.send_email = true

            if @message.save
              flash[:success] = "Message has been sent."
              session.delete(:message_post_id_hash)
              if signed_in?
                redirect_to :controller => :messages, :action => :index
              else
                 if not request.referer.blank?
                  redirect_to request.referer
                else
                  redirect_to :controller => :posts, :action => :index
                end
              end
            else
              @post = message_post
              render 'new'
            end
          else
            #TODO redirect to report an issue
            flash[:error] = 'You appear to be doing something we are not familiar with.  Please let us know what it is you were trying to do.'
            redirect_to root_path
          end
        else
          #TODO redirect to report an issue
          flash[:error] = 'You appear to be doing something we are not familiar with.  Please let us know what it is you were trying to do.'
          redirect_to root_path
        end
      end
    end
  end

  #TODO ajaxify this method
  def delete
    if not params[:id].blank?
      if message = Message.first(:conditions => ['id_hash = ? AND recipient_user_id = ?', params[:id], current_user.id], :select => 'id,status')
        message.update_attribute(:status, STATUS_DELETED)
        flash[:success] = "Message deleted"
      else
        flash[:error] = "Message not found"
      end
      redirect_to :action => :index
    end
  end
end

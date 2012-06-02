class MessagesController < ApplicationController
  before_filter :signed_in_user, :except => [:new, :create]

  def index
    @messages = Message.paginate(page: params[:page], :per_page => 10, :conditions => ['recipient_user_id = ? AND status != ?', current_user.id, STATUS_DELETED], :order => 'id desc, status desc')
    @unread = Message.count(:conditions => ['recipient_user_id = ? AND status = ?', current_user.id, STATUS_UNREAD])
  end

  def show
    if not params[:id].blank?
      if @message = Message.first(:conditions => ['id_hash = ? AND recipient_user_id = ?', params[:id], current_user.id], :select => 'id,status,body,created_at,id_hash,contact_info_json')
        @message.update_attribute(:status, STATUS_READ)
      else
        flash[:error] = "Message not found"
      end
    end
  end

  def reply

  end

  def new
    @message ||= Message.new

    if not params[:id].blank?
      session.delete(:message_post)
      if post = Post.first(:conditions => ['id_hash = ?', params[:id]])
        session[:message_post] = post
      end
    end

    if not session[:message_post].blank?
      @message_post = session[:message_post]
    end
  end

  def create
    if request.post?
      if session[:message_post]
        if params[:message]
          @message = Message.new(params[:message])
          if signed_in?
            @message.contact_info_json = current_user.email
          end

          @message.creator_user_id = signed_in? ? current_user.id : nil
          @message.recipient_user_id = session[:message_post].user_id
          @message.source = 'post'
          @message.source_id = session[:message_post].id
          @message.send_email = true

          if @message.save
            flash[:succcess] = "Message has been sent."
            redirect_to :controller => :posts, :action => :show, :id => session[:message_post].id
          else
            @message_post = session[:message_post]
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

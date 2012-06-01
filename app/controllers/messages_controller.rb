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
      #TODO make contact info optional as the user may be logged in
      #TODO make the source and source_id more flexible to other options
      #TODO parse the contact_info for phone numbers and emails, force email and put the rest in the json
      if session[:message_post]
        contact_info = params[:contact_info]
        message = params[:message]
        Message.create(
            :creator_user_id => signed_in? ? current_user.user_id : nil,
            :recipient_user_id => session[:message_post].user_id,
            :source => 'post',
            :source_id => session[:message_post].id,
            :contact_info_json => {:email => params[:contact_info]}.to_json,
            :body => params[:message],
            :send_email => true
        )
        flash[:succcess] = "Message has been sent."
        redirect_to :controller => :posts, :action => :show, :id => session[:message_post].id
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

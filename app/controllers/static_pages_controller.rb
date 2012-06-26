class StaticPagesController < ApplicationController
  before_filter :invite_only_home_redirect, only: [:home]

  def home
    @posts = Post.paginate(page: params[:page], :per_page => 2, :conditions => ['open = ? AND status != ?', true, STATUS_DELETED], :order => 'id desc')
    if signed_in?
      @primary_twitter_account = ApiAccount.first(:conditions => ['user_id = ? AND status = ?', current_user.id, STATUS_PRIMARY])
    end
  end

  def about
  end

  def contact
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    if request.post?
      if not @name.blank?
        if not @email.blank?
          if not @message.blank?
            to = 'danlogan@slinggit.com,chrisklein@slinggit.com,philbeadle@slinggit.com,chasecourington@slinggit.com'
            from = 'Contact Us <noreply@slinggit.com>'
            subject = "Inquiry from #{@name}"
            content = "<p>#{@name}<p/></br></br><p>#{@email}</p></br></br><p>#{@message}</p>"
            reply_to = @email
            UserMailer.generic_internal_email(to, from, subject, content, reply_to).deliver
            flash.now[:success] = "Thank you much for your inquiry.  An email has been passed along to the Slinggit team."
            @name = @email = @message = ''
          else
            flash.now[:error] = "We would be tickled pink if you could throw together a quick message for us."
          end
        else
          flash.now[:error] = "Without an email address it may prove rather difficult to get in touch with you."
        end
      else
        flash.now[:error] = "We were hoping you could give us a name so we know who to address."
      end
    end
  end

  def help
  end

end

class UserMailer < ActionMailer::Base
  default from: "Slinggit <noreply@slinggit.com>"

  EXECUTIVES = 'danlogan@slinggit.com,chrisklein@slinggit.com,philbeadle@slinggit.com,chasecourington@slinggit.com'

  def welcome_email(user)
    @user = user
    @url = "#{BASEURL}/users/verify_email/#{user.email_activation_code}"
    mail(:to => user.email, :subject => "Welcome to Slinggit")
  end

  def api_account_post_failure(api_account)
    @user = User.first(:conditions => ['id = ?', api_account.user_id], :select => ['email,name'])
    @api_account = api_account
    mail(:to => @user.email, :subject => "Trouble posting to your #{api_account.api_source.titleize} account")
  end

  def password_reset(user)
    @user = user
    mail(:to => user.email, :subject => "Password reset for Slinggit.com")
  end

  def problem_report(exception, user)
    @exception = exception
    @current_user = user
    mail(:to => EXECUTIVES, :from => 'Problem Report <problem_report@slinggit.com>', :subject => "Problem Report - #{exception.message}")
  end

  def terms_violation_notification(user, violation_reason)
    @violation_reason = violation_reason
    @user = user
    mail(:to => user.email, :subject => "Your account has been suspended")
  end

  def account_deleted(user)
    @user = user
    @reactive_url = "#{BASEURL}/users/reactivate/#{user.account_reactivation_code}"
    mail(:to => user.email, :subject => "Your account has been deleted")
  end

  def inform_admin_account_deleted(user)
    @user = user
    @user_feedbacks = UserFeedback.all(:conditions => ['user_id = ?', user.id])
    @reactive_url = "#{BASEURL}/users/reactivate/#{user.account_reactivation_code}"
    mail(:to => EXECUTIVES, :from =>'From Beyond The Grave <deleted_account@slinggit.com>', :subject => "User deleted account")
  end

end

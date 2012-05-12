class UserMailer < ActionMailer::Base
  default from: "noreply@slinggit.com"

  def welcome_email(user)
    @user = user
    @url = "#{BASEURL}/signin"
    mail(:to => user.email, :subject => "Welcome to Slinggit")
  end

  def api_account_post_failure(api_account)
    @user = User.first(:conditions => ['id = ?', api_account.user_id], :select => ['email,name'])
    @api_account = api_account
    mail(:to => @user.email, :subject => "Trouble posting to your #{api_account.api_source.titleize} account")
  end

  def password_reset(user)
    @user = user
    mail(:to => @user.email, :subject => "Password reset for Slinggit.com")
  end

  def deliver_problem_report(exception)
    #TODO IMPLEMENT
  end

end

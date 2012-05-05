class UserMailer < ActionMailer::Base
  default from: "noreply@slinggit.com"

  def welcome_email(user)
    @user = user
    @url = "#{BASEURL}/signin"
    mail(:to => user.email, :subject => "Welcome to Slinggit")
  end
end

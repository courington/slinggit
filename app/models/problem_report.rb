#create_table :problem_reports do |t|
#  t.string :exception_string
#  t.string :exception_class
#  t.text :exception_backtrace
#  t.integer :logged_in_user_id
#  t.string :status, :default => 'new'
#  t.timestamps
#end

class ProblemReport < ActiveRecord::Base
  #not a column we need but we might not always want to send an email
  attr_accessor :send_email

  attr_accessible :exception_message, :exception_class, :exception_backtrace, :signed_in_user_id, :status, :send_email

  after_create :send_problem_report_email

  def send_problem_report_email
    if send_email
      UserMailer.problem_report(self).deliver
    end
  end
end



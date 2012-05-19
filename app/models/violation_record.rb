#create_table :violation_records do |t|
#  t.integer :user_id
#  t.string :violation
#  t.string :violation_source
#  t.id :violation_source_id
#  t.string :action_taken
#  t.timestamps
#end

class ViolationRecord < ActiveRecord::Base
  attr_accessible :user_id, :violation, :violation_source, :violation_source_id, :action_taken
  after_create :send_terms_violation_notification

  def send_terms_violation_notification
    #inform the user that their account has been suspended
    user = User.first(:conditions => ['id = ?', self.user_id])
    UserMailer.terms_violation_notification(user, self.violation).deliver
  end
end

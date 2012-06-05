# == Schema Information
#
#create_table :flagged_contents do |t|
#  t.integer :creator_user_id
#  t.string :content_source
#  t.integer :content_id
#  t.timestamps
#end

class FlaggedContent < ActiveRecord::Base
  attr_accessible :creator_user_id, :content_source, :content_id
  after_create :send_email_to_execs

  def send_email_to_execs
    UserMailer.flagged_content_notification(self).deliver
  end
end

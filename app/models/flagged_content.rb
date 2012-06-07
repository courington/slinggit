# == Schema Information
#
# Table name: flagged_contents
#
#  id              :integer         not null, primary key
#  creator_user_id :integer
#  content_source  :string(255)
#  content_id      :integer
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

class FlaggedContent < ActiveRecord::Base
  attr_accessible :creator_user_id, :content_source, :content_id
  after_create :send_email_to_execs

  def send_email_to_execs
    UserMailer.flagged_content_notification(self).deliver
  end
end

#create_table :invitations do |t|
#  t.string :email_address
#  t.string :location
#  t.text :comment
#  t.string :status, :default => 'pending'
#t.timestamps
#end

class Invitation < ActiveRecord::Base
  attr_accessible :email_address, :location, :comment, :status

  def is_active?
    self.status == 'active'
  end
end

# == Schema Information
#
# Table name: invitations
#
#  id            :integer         not null, primary key
#  email_address :string(255)
#  location      :string(255)
#  comment       :text
#  status        :string(255)     default("pending")
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#

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

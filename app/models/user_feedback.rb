#create_table :user_feedbacks do |t|
#  t.integer :user_id
#  t.string :source
#  t.text :information
#  t.timestamps
#end

class UserFeedback < ActiveRecord::Base
  attr_accessible :user_id, :source, :information
end

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
end

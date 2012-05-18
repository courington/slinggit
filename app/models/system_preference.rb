#create_table :system_preferences do |t|
#  t.string :preference_key
#  t.string :preference_value
#  t.string :constraints
#  t.string :descripion
#  t.datetime :start_date
#  t.datetime :end_date
#  t.boolean :active, :default => false
#end

class SystemPreference < ActiveRecord::Base
  attr_accessible :preference_key, :preference_value, :constraints, :description, :start_date, :end_date, :active

  def is_active?
    self.status == 'active'
  end
end

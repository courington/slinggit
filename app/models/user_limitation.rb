class UserLimitation < ActiveRecord::Base
  attr_accessible :user_id, :limitation_type, :limit, :frequency, :frequency_type, :active
end

class MobileSession < ActiveRecord::Base
  attr_accessible :user_id, :unique_identifier, :mobile_auth_token, :active
end

class UserLogin < ActiveRecord::Base
  attr_accessible :user_id, :user_agent, :ip_address, :url_referrer, :login_source, :session_json, :paramaters_json
end
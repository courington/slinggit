class ApiAccount < ActiveRecord::Base
  before_create :create_api_id_hash
  attr_accessible :user_id, :api_id, :api_source, :oauth_token, :oauth_secret, :real_name, :user_name, :image_url, :description, :language, :location, :status

  private

  def create_api_id_hash
    self.api_id_hash = Digest::SHA1.hexdigest(self.api_id.to_s)
  end

end
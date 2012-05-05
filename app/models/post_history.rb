class PostHistory < ActiveRecord::Base
  attr_accessible :id, :content, :created_at, :hashtag_prefix, :location, :open, :photo_content_type, :photo_file_name, :photo_file_size, :photo_updated_at, :price, :recipient_api_account_ids, :updated_at, :user_id
end
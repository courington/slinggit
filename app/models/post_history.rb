# == Schema Information
#
# Table name: post_histories
#
#  id                        :integer         not null, primary key
#  content                   :string(255)
#  created_at                :datetime
#  hashtag_prefix            :string(255)
#  location                  :string(255)
#  open                      :boolean
#  photo_content_type        :string(255)
#  photo_file_name           :string(255)
#  photo_file_size           :integer
#  photo_updated_at          :datetime
#  price                     :decimal(, )
#  recipient_api_account_ids :string(255)
#  updated_at                :datetime
#  user_id                   :integer
#  reply_to                  :string(255)
#

class PostHistory < ActiveRecord::Base
  attr_accessible :id, :content, :created_at, :hashtag_prefix, :location, :open, :photo_content_type, :photo_file_name, :photo_file_size, :photo_updated_at, :price, :recipient_api_account_ids, :updated_at, :user_id, :reply_to
end

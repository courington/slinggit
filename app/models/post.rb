# == Schema Information
#
# Table name: posts
#
#  id                 :integer         not null, primary key
#  content            :string(255)
#  user_id            :integer
#  created_at         :datetime        not null
#  updated_at         :datetime        not null
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer
#  photo_updated_at   :datetime
#  hashtag_prefix     :string(255)
#  price              :decimal(8, 2)
#  open               :boolean         default(TRUE)
#

class Post < ActiveRecord::Base
  attr_accessible :content, :photo, :hashtag_prefix, :price, :open
  
  belongs_to :user
  has_attached_file :photo, styles: { :medium => "300x300>" },
                    url: "/assets/posts/:id/:style/:basename.:extension",
  							    path: ":rails_root/public/assets/posts/:id/:style/:basename.:extension"

  validates :content, presence: true, length: { maximum: 100 }
  validates :user_id, presence: true
  validates :hashtag_prefix, presence: true, length: {maximum: 10 }
  validates :price, presence: true, :format => { :with => /^\d+??(?:\.\d{0,2})?$/ }, :numericality => {:greater_than_or_equal_to => 0.01}
  # validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  default_scope order: 'posts.updated_at DESC'
end

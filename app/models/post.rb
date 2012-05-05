# == Schema Information
#
# Table name: posts
#
#  id                        :integer         not null, primary key
#  content                   :string(255)
#  user_id                   :integer
#  created_at                :datetime        not null
#  updated_at                :datetime        not null
#  photo_file_name           :string(255)
#  photo_content_type        :string(255)
#  photo_file_size           :integer
#  photo_updated_at          :datetime
#  hashtag_prefix            :string(255)
#  price                     :decimal(8, 2)
#  open                      :boolean         default(TRUE)
#  api_account_id            :integer
#  post_id                   :string(255)
#  last_result               :string(255)
#  recipient_api_account_ids :string(255)
#  location                  :string(255)
#

class Post < ActiveRecord::Base
  before_save :create_post_history

  attr_accessible :content, :user_id, :photo, :hashtag_prefix, :location, :price, :open

  belongs_to :user
  has_many :comments, dependent: :destroy

  has_attached_file :photo, styles: {:medium => "300x300#", :search => '80x80#'},
                    url: "/assets/posts/:id/:style/:basename.:extension",
                    path: ":rails_root/public/assets/posts/:id/:style/:basename.:extension"
  VALID_LOCATION_REGEX = /\A[a-z0-9]{,20}\z/i #We may want to force either numbers or letters at a later date
  validates :location, length: {maximum: 10}, format: {with: VALID_LOCATION_REGEX, :message => "cannot be greater then 10 characters and cannot contain spaces"}
  validates :content, presence: true, length: {maximum: 100}
  validates :user_id, presence: true
  VALID_HASHTAG_REGEX = /\A[a-z0-9_]{,20}\z/i
  validates :hashtag_prefix, presence: true, length: {maximum: 10}, format: {with: VALID_HASHTAG_REGEX, :message => "(Item) cannot be greater then 10 characters and cannot contain spaces.  Characters must be either a-z, 0-9, or _"}
  validates :price, presence: true, :format => {:with => /^\d+??(?:\.\d{0,2})?$/}, :numericality => {:greater_than_or_equal_to => 0.01}
                                              # validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  default_scope order: 'posts.updated_at DESC'

  def create_post_history
    if not self.id.blank?
      current_post_before_save = Post.first(:conditions => ['id = ?', self.id])
      if current_post_before_save
        PostHistory.create(current_post_before_save.attributes)
      end
    end
  end
end

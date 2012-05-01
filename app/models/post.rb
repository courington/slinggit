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
#  api_account_id     :integer
#  post_id            :string(255)
#  last_result        :string(255)
#

class Post < ActiveRecord::Base
  attr_accessible :content, :photo, :hashtag_prefix, :price, :open

  belongs_to :user
  has_many :comments, dependent: :destroy

  has_attached_file :photo, styles: {:medium => "300x300#"},
                    url: "/assets/posts/:id/:style/:basename.:extension",
                    path: ":rails_root/public/assets/posts/:id/:style/:basename.:extension"
  validates_presence_of :recipient_api_account_ids, :message => "must have at least one selected"
  validates :content, presence: true, length: {maximum: 100}
  validates :user_id, presence: true
  validates :hashtag_prefix, presence: true, length: {maximum: 10}
  validates :price, presence: true, :format => {:with => /^\d+??(?:\.\d{0,2})?$/}, :numericality => {:greater_than_or_equal_to => 0.01}
  # validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  default_scope order: 'posts.updated_at DESC'

  def do_post
    #This will contain a lot more logic when Im not tired... Im going to bed now.
    #TODO add in last result, post id, yada yada
    if self.post_id.blank?
      self.recipient_api_account_ids.split(',').each do |api_account_id|
        twitter_client = nil
        if api_account_id.to_i == 0
          #twitter_client = Twitter::Client.new(oauth_token: Rails.configuration.slinggit_client_atoken, oauth_token_secret: Rails.configuration.slinggit_client_asecret)
        else
          api_account = ApiAccount.first(:conditions => ['id = ? AND user_id = ?', api_account_id.to_i, self.user_id], :select => 'oauth_token,oauth_secret')
          twitter_client = Twitter::Client.new(oauth_token: api_account.oauth_token, oauth_token_secret: api_account.oauth_secret)
        end
        if not twitter_client.blank?
          twitter_client.update("##{self.hashtag_prefix}forsale #{self.content} - #{self.price} | Slinggit")
        end
      end
    end
  end
end

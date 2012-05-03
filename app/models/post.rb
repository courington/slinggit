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
  attr_accessible :content, :user_id, :photo, :hashtag_prefix, :location, :price, :open, :api_account, :post_id, :last_result

  belongs_to :user
  has_many :comments, dependent: :destroy

  has_attached_file :photo, styles: {:medium => "300x300#"},
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

  def do_post
    #This will contain a lot more logic when Im not tired... Im going to bed now.
    #TODO add in last result, post id, yada yada
    if self.post_id.blank?
      twitter_client = nil
      if api_account_id == 0
        twitter_client = Twitter::Client.new(oauth_token: Rails.configuration.slinggit_client_atoken, oauth_token_secret: Rails.configuration.slinggit_client_asecret)
      else
        @api_account = ApiAccount.first(:conditions => ['id = ? AND user_id = ?', api_account_id.to_i, self.user_id], :select => 'oauth_token,oauth_secret')
        if @api_account
          twitter_client = Twitter::Client.new(oauth_token: @api_account.oauth_token, oauth_token_secret: @api_account.oauth_secret)
        else
          #handle this error... we were given an id that doesnt exist
        end
      end

      if not twitter_client.blank?
        begin
          result = twitter_client.update("##{self.hashtag_prefix}forsale #{self.content} - $#{"%.0f" % self.price} | Slinggit")
          self.post_id = result.attrs['id_str']
          self.last_result = 'successful post'
          self.save
        rescue Exception => e
          if e.is_a? Twitter::Error::Unauthorized
            if api_account = ApiAccount.first(:conditions => ['id = ? AND user_id = ?', self.api_account_id, self.user_id])
              api_account.reauth_required = 'yes'
            end
          end
          self.last_result = "#{e.class.to_s}-#{e.to_s}"
          self.save
        end
      end
    end
  end

  # Logic for constructing twitter message.
  def tweet_constructor(client)
    #TODO need to add the url to the post to the tweet
    client.update("##{self.hashtag_prefix}forsale ##{self.location} #{self.content} - #{self.price} | Slinggit")
  end 
end

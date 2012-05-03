#t.id :user_id
#t.id :api_account_id
#t.string :post_id
#t.string :content
#t.string :status, :default => 'no attempt'
#t.last_result
#t.timestamps

class TwitterPost < ActiveRecord::Base
  attr_accessible :user_id, :api_account_id, :post_id, :content
  belongs_to :api_account
  belongs_to :post
  def do_post
    self.update_attribute(:status, 'processing')

    if self.twitter_post_id.blank?
      twitter_client = nil
      if api_account_id == 0
        twitter_client = Twitter::Client.new(oauth_token: Rails.configuration.slinggit_client_atoken, oauth_token_secret: Rails.configuration.slinggit_client_asecret)
      else
        if self.api_account
          twitter_client = Twitter::Client.new(oauth_token: self.api_account.oauth_token, oauth_token_secret: self.api_account.oauth_secret)
        else
          #handle this error... we were given an id that doesnt exist
        end
      end

      if not twitter_client.blank?
        begin
          result = twitter_client.update("##{self.post.hashtag_prefix}forsale #{self.post.content} - $#{"%.0f" % self.post.price} | Slinggit")
          self.twitter_post_id = result.attrs['id_str']
          self.last_result = 'successful post'
          self.status = 'done'
          self.save
        rescue Exception => e
          if e.is_a? Twitter::Error::Unauthorized
            if self.api_account
              self.api_account.reauth_required = 'yes'
            end
          end
          self.last_result = "#{e.class.to_s}-#{e.to_s}"
          self.status = 'failed'
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
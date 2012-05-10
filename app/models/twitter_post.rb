# == Schema Information
#
# Table name: twitter_posts
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  api_account_id  :integer
#  post_id         :integer
#  content         :string(255)
#  twitter_post_id :string(255)
#  status          :string(255)     default("new")
#  last_result     :string(255)     default("no attempt")
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

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

  PROCESSING_STATUS = 'processing'
  FAILED_STATUS = 'failed'
  SUCCEEDED_STATUS = 'done'
  SUCCEEDED_LAST_RESULT = 'successful post'
  SUCCEEDED_REPOST_LAST_RESULT = 'successful - duplicate post not submitted again'

  def do_post
    @post_start_time = Time.now
    self.update_attribute(:status, PROCESSING_STATUS)
    if not has_been_post?
      twitter_client = nil
      if api_account_id == 0
        twitter_client = Twitter::Client.new(oauth_token: Rails.configuration.slinggit_client_atoken, oauth_token_secret: Rails.configuration.slinggit_client_asecret)
      else
        if self.api_account
          twitter_client = Twitter::Client.new(oauth_token: self.api_account.oauth_token, oauth_token_secret: self.api_account.oauth_secret)
        end
      end

      if not twitter_client.blank?
        begin
          result = tweet_constructor(twitter_client)
          finalize(SUCCEEDED_STATUS, {:last_result => SUCCEEDED_LAST_RESULT, :twitter_post_id => result.attrs['id_str']}) and return
        rescue Exception => e
          if e.is_a? Twitter::Error::Unauthorized
            if self.api_account
              finalize(FAILED_STATUS, {:api_account_reauth_required => 'yes', :last_result => "api_account-yes // caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
            else
              finalize(FAILED_STATUS, {:last_result => "api_account-no // caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
            end
          else
            finalize(FAILED_STATUS, {:last_result => "caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
          end
        end
      else
        finalize(FAILED_STATUS, {:last_result => "twitter client could not be established"}) and return
      end
    else
      finalize(SUCCEEDED_STATUS, {:last_result => SUCCEEDED_REPOST_LAST_RESULT}) and return
    end
  end

  def finalize(status, options = {})
    self.last_result = options[:last_result] + " // dur=#{Time.now - @post_start_time}-sec"
    self.status = status
    self.twitter_post_id = options[:twitter_post_id]
    if options[:api_account_reauth_required]
      if self.api_account
        self.api_account.reauth_required = options[:api_account_reauth_required]
        UserMailer.api_account_post_failure(self.api_account).deliver
      end
    end
    self.save
  end

  def has_been_post?
    if self.twitter_post_id.blank?
      return false
    else
      return true
    end
  end

# Logic for constructing twitter message.
  def tweet_constructor(client)
    content = self.post.content.truncate(60, :omission => "...")
    redirect = Redirect.get_or_create(
        :target_uri => "#{BASEURL}/posts/#{self.post.id}"
    )
    #changed to use our url shortner... if twitter does it for us great... but this will track the number of clicks if we use our own
    #NOTE... if testing on localhost, the link wont be clickable in twitter... but once a .com is added it will be.
    if self.post.photo_file_name.blank?
      return client.update("##{self.post.hashtag_prefix}forsale ##{self.post.location} #{content} - $#{"%.0f" % self.post.price} | #{redirect.get_short_url}")
    else
      return client.update_with_media("##{self.post.hashtag_prefix}forsale ##{self.post.location} #{content} - $#{"%.0f" % self.post.price} | #{redirect.get_short_url}", File.new(self.post.photo.path(:medium)))
    end
  end

end

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

  SUCCESS_LAST_RESULT = 'successful post'
  SUCCESS_REPOST_LAST_RESULT = 'successful - duplicate post not submitted again'
  SUCCESS_NEVER_POSTED = 'successful - post was never on twitter'
  SUCCESS_UNDO_POST = 'successful - removed post from twitter'

  def do_post
    @start_time = Time.now
    self.update_attribute(:status, STATUS_PROCESSING)
    if not has_been_posted?
      if not self.api_account.blank?
        if not self.api_account.status == STATUS_DELETED
          twitter_client = nil
          if self.api_account
            twitter_client = Twitter::Client.new(oauth_token: self.api_account.oauth_token, oauth_token_secret: self.api_account.oauth_secret)
          end
          if not twitter_client.blank?
            begin
              result = tweet_constructor(twitter_client)
              debugger
              finalize(STATUS_SUCCESS, {:last_result => SUCCESS_LAST_RESULT, :twitter_post_id => result.attrs['id_str']}) and return
            rescue Exception => e
              if e.is_a? Twitter::Error::Unauthorized
                if self.api_account
                  finalize(STATUS_FAILED, {:api_account_reauth_required => 'yes', :last_result => "api_account-yes // caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
                else
                  finalize(STATUS_FAILED, {:last_result => "api_account-no // caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
                end
              else
                finalize(STATUS_FAILED, {:last_result => "caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
              end
            end
          else
            finalize(STATUS_FAILED, {:last_result => "twitter client could not be established"}) and return
          end
        else
          finalize(STATUS_FAILED, {:last_result => "api account has been deleted"}) and return
        end
      else
        finalize(STATUS_FAILED, {:last_result => "api_account_id does not exist"}) and return
      end
    else
      finalize(STATUS_SUCCESS, {:last_result => SUCCESS_REPOST_LAST_RESULT}) and return
    end
  end

  def undo_post
    @start_time = Time.now
    self.update_attribute(:status, STATUS_PROCESSING)
    if has_been_posted?
      if not self.api_account.blank?
        twitter_client = nil
        if self.api_account
          twitter_client = Twitter::Client.new(oauth_token: self.api_account.oauth_token, oauth_token_secret: self.api_account.oauth_secret)
        end
        if not twitter_client.blank?
          begin
            result = twitter_client.status_destroy(self.twitter_post_id)
            finalize(STATUS_SUCCESS, {:last_result => SUCCESS_UNDO_POST, :twitter_post_id => nil}) and return
          rescue Exception => e
            #were going to ban this person any way so we dont need to tell them that their not authorized
            finalize(STATUS_FAILED, {:last_result => "deleting_post // caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
          end
        else
          finalize(STATUS_FAILED, {:last_result => "deleting_post // twitter client could not be established"}) and return
        end
      else
        finalize(STATUS_FAILED, {:last_result => "deleting_post // api_account_id does not exist"}) and return
      end
    else
      finalize(STATUS_SUCCESS, {:last_result => SUCCESS_NEVER_POSTED}) and return
    end
  end

  def finalize(status, options = {})
    self.last_result = options[:last_result] + " // dur=#{Time.now - @start_time}-sec"
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

  def has_been_posted?
    if not self.twitter_post_id.blank? or self.status == STATUS_DELETED
      return true
    else
      return false
    end
  end

# Logic for constructing twitter message.
  def tweet_constructor(client)
    content = self.post.content.truncate(54, :omission => "...")
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

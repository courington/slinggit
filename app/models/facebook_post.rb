# == Schema Information
#
#create_table :facebook_posts do |t|
#  t.integer :user_id
#  t.integer :api_account_id
#  t.integer :post_id
#  t.string :name #name
#  t.string :message #message
#  t.string :caption #caption
#  t.string :description #description
#  t.string :image_url #picture
#  t.string :link_url #link
#  t.string :facebook_post_id
#  t.string :status
#  t.string :last_result
#  t.timestamps
#end

class FacebookPost < ActiveRecord::Base
  attr_accessible :user_id, :api_account_id, :post_id, :name, :message, :caption, :description, :image_url, :link_url, :facebook_post_id, :status, :last_result
  belongs_to :api_account
  belongs_to :post

  PROCESSING_STATUS = 'processing'
  FAILED_STATUS = 'failed'
  SUCCEEDED_STATUS = 'done'
  SUCCEEDED_LAST_RESULT = 'successful post'
  SUCCEEDED_REPOST_LAST_RESULT = 'successful - duplicate post not submitted again'
  SUCCEEDED_NEVER_POSTED = 'successful - post was never on facebook'
  SUCCEEDED_UNDO_POST = 'successful - removed post from facebook'

  def do_post
    @start_time = Time.now
    self.update_attribute(:status, PROCESSING_STATUS)
    if not has_been_posted?
      if not self.api_account.blank?
        if not self.api_account.status == STATUS_DELETED
          begin
            result = post_constructor
              #finalize(SUCCEEDED_STATUS, {:last_result => SUCCEEDED_LAST_RESULT, :facebook_post_id => result.attrs['id_str']}) and return
          rescue Exception => e
            finalize(FAILED_STATUS, {:last_result => "caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
          end
        else
          finalize(FAILED_STATUS, {:last_result => "api account has been deleted"}) and return
        end
      else
        finalize(FAILED_STATUS, {:last_result => "api_account_id does not exist"}) and return
      end
    else
      finalize(SUCCEEDED_STATUS, {:last_result => SUCCEEDED_REPOST_LAST_RESULT}) and return
    end
  end

  def undo_post

  end

  def finalize(status, options = {})
    self.last_result = options[:last_result] + " // dur=#{Time.now - @start_time}-sec"
    self.status = status
    self.facebook_post_id = options[:facebook_post_id]
    if options[:api_account_reauth_required]
      self.api_account.reauth_required = options[:api_account_reauth_required]
      UserMailer.api_account_post_failure(self.api_account).deliver
    end
    self.save
  end

  def has_been_posted?
    if self.facebook_post_id.blank?
      return false
    else
      return true
    end
  end

# Logic for constructing twitter message.
  def post_constructor
    redirect_url = self.link_url
    if redirect_url.blank?
      redirect_url = "#{BASEURL}/posts/#{self.post.id}"
    end

    redirect = Redirect.get_or_create(
        :target_uri => "#{redirect_url}"
    )

    uri = URI.parse "https://graph.facebook.com/#{self.api_account.api_id}/feed"
    http = Net::HTTP.new uri.host, uri.port
    if uri.port == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    result = http.post(uri.path, URI.escape("access_token=#{self.api_account.oauth_secret}&link=#{redirect.get_short_url}/&name=#{self.name}&message=#{self.message}&description=#{self.description}&caption=#{self.caption}&picture=#{self.image_url}"))

    #result = `curl -F 'app_id=#{Rails.configuration.facebook_app_id}' -F 'access_token=#{self.api_account.oauth_secret}' -F 'name=#{self.name}&message=#{self.message}&caption=#{self.caption}&description=#{self.description}&picture=#{self.message}&link=#{self.message}' https://graph.facebook.com/#{self.api_account.api_id}/feed`
    puts result
    #changed to use our url shortner... if twitter does it for us great... but this will track the number of clicks if we use our own
    #NOTE... if testing on localhost, the link wont be clickable in twitter... but once a .com is added it will be.
    #if self.post.photo_file_name.blank?
    #  return client.update("##{self.post.hashtag_prefix}forsale ##{self.post.location} #{content} - $#{"%.0f" % self.post.price} | #{redirect.get_short_url}")
    #else
    #  return client.update_with_media("##{self.post.hashtag_prefix}forsale ##{self.post.location} #{content} - $#{"%.0f" % self.post.price} | #{redirect.get_short_url}", File.new(self.post.photo.path(:medium)))
    #end

    #expanded_width = expanded_height = '398px'
    #attachment = {
    #    'name' => video_post.title,
    #    'caption' =>  @recipient.caption.blank? ? nil : @recipient.caption,
    #    'description' => @recipient.description.blank? ? nil : @recipient.description,
    #    'href' => @video_location,
    #    'media' => [
    #        {
    #            'type' => 'flash',
    #            'swfsrc' => "#{BASEURL}/FacebookPlayer.swf",
    #            'imgsrc' => self.href_to_image,
    #            'width' => '90px',
    #            'height' => '90px',
    #            'expanded_width' => expanded_width,
    #            'expanded_height' => expanded_height,
    #            'flashvars' => flashvars.to_query
    #        }
    #    ]
    #}
    #
    #if not @is_original_post
    #  if api_account = ApiAccount.find(:last, :conditions => ['api_source = "facebook" AND api_id = ? and status = "active"', @recipient.recipient_facebook_id], :select => 'secret')
    #    access_token = api_account.secret
    #  end
    #end
    #
    #if @recipient.post_id.nil?
    #  post_params = {
    #      'access_token' => access_token,
    #      'attachment' => attachment.to_json,
    #      'format' => 'json'
    #  }
  end

end

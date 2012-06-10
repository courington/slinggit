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

  SUCCESS_LAST_RESULT = 'successful post'
  SUCCESS_REPOST_LAST_RESULT = 'successful - duplicate post not submitted again'
  SUCCESS_NEVER_POSTED = 'successful - post was never on facebook'
  SUCCESS_UNDO_POST = 'successful - removed post from facebook'

  def do_post
    @start_time = Time.now
    self.update_attribute(:status, PROCESSING_STATUS)
    if not has_been_posted?
      if not self.api_account.blank?
        if not self.api_account.status == STATUS_DELETED
          begin
            response = post_constructor
            result = ActiveSupport::JSON.decode(response.body)
            if result['id']
              finalize(STATUS_SUCCESS, {:last_result => SUCCESS_LAST_RESULT, :facebook_post_id => result.attrs['id_str']}) and return
            else
              finalize(STATUS_FAILED, {:last_result => result}) and return
            end
          rescue Exception => e
            finalize(STATUS_FAILED, {:last_result => "caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
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
        begin
          #uri = URI.parse "DELETE https://graph.facebook.com/#{self.facebook_post_id}?access_token=#{self.api_account.oauth_secret}"
          #http = Net::HTTP.new(uri.host)
          #if uri.port == 443
          #  http.use_ssl = true
          #  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          #end
          #param_string = "access_token=#{self.api_account.oauth_secret}&link=#{redirect.get_short_url}/&name=#{self.name}&message=#{self.message}&description=#{self.description}&caption=#{self.caption}"
          #if self.post.has_photo?
          #  param_string << "&picture=#{self.image_url}"
          #end
          #return http.post(uri.path, URI.escape(param_string))
          #
          #
          #finalize(SUCCEEDED_STATUS, {:last_result => SUCCEEDED_UNDO_POST, :facebook_post_id => nil}) and return
        rescue Exception => e
          finalize(STATUS_FAILED, {:last_result => "deleting_post // caught exception // #{e.class.to_s}-#{e.to_s}"}) and return
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
    self.facebook_post_id = options[:facebook_post_id]
    if options[:api_account_reauth_required]
      self.api_account.reauth_required = options[:api_account_reauth_required]
      UserMailer.api_account_post_failure(self.api_account).deliver
    end
    self.save
  end

  def has_been_posted?
    if not self.facebook_post_id.blank? or self.status == STATUS_DELETED
      return true
    else
      return false
    end
  end

# Logic for constructing facebook message.
  def post_constructor
    redirect_url = self.link_url
    if redirect_url.blank?
      redirect_url = "#{BASEURL}/posts/#{self.post.id}"
    end

    redirect = Redirect.get_or_create(
        :target_uri => "#{redirect_url}"
    )

    uri = URI.parse "https://graph.facebook.com/#{self.api_account.api_id.to_i + 22}/feed"
    http = Net::HTTP.new(uri.host)
    if uri.port == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    param_string = "access_token=#{self.api_account.oauth_secret}&link=#{redirect.get_short_url}/&name=#{self.name}&message=#{self.message}&description=#{self.description}&caption=#{self.caption}"
    if self.post.has_photo?
      param_string << "&picture=#{self.image_url}"
    end
    return http.post(uri.path, URI.escape(param_string))
  end

end

#create_table :messages do |t|
#  t.integer :creator_user_id
#  t.integer :recipient_user_id
#  t.string :source
#  t.integer :source_id
#  t.string :contact_info_json
#  t.string :body, :limit => 1200
#  t.string :status
#  t.timestamps
#end

class Message < ActiveRecord::Base
  attr_accessible :creator_user_id, :recipient_user_id, :source, :source_id, :contact_info_json, :body, :status, :send_email
  attr_accessor :send_email

  before_create :create_id_hash
  after_create :send_new_message_email

  def contact_info
    contact_info_hash = HashWithIndifferentAccess.new
    decoded_contact_info = ActiveSupport::JSON.decode(self.contact_info_json)
    if not decoded_contact_info.blank?
      decoded_contact_info.each do |key, value|
        contact_info_hash[key] = value
      end
      return contact_info_hash
    end
    return nil
  end

  def send_new_message_email
    if send_email
      UserMailer.new_message(self).deliver
    end
  end

  def create_id_hash
    self.id_hash = Digest::SHA1.hexdigest(self.id.to_s + Time.now.to_s)
  end

  def source_object(fields_to_select = nil)
    #to utalize this method the source for the record needs to represent a table model in its lower case singular form
    #example -- post, post_history, api_account
    #if it doesnt, it wont break, but it will just return nil
    if not @source_object.blank?
      return @source_object
    else
      if not self.source_id.blank?
        source_as_model = self.source.split('_').map { |x| x.titleize }.join
        begin
          query = "#{source_as_model}.first(:conditions => ['id = ?', #{self.source_id}]"
          if not fields_to_select.blank?
            if fields_to_select[:table] and fields_to_select[:columns]
              if fields_to_select[:table] == source_as_model
                query << ", :select => '#{fields_to_select[:columns]}'"
              end
            end
          end
          query << ")"
          @source_object = eval(query)
          return @source_object
        rescue
          return nil
        end
      end
    end
  end
end

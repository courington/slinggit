#create_table :additional_photos do |t|
#  t.integer :user_id
#  t.string :source
#  t.integer :source_id
#  t.string :photo_file_name
#  t.string :photo_content_type
#  t.integer :photo_file_size
#  t.datetime :photo_updated_at
#  t.string :status
#end

class Post < ActiveRecord::Base
  attr_accessible :user_id, :source, :source_id, :phot_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :status
  has_attached_file :photo, styles: {:medium => "300x300>", :search => '80x80>'},
                    :convert_options => {
                      :medium => "-auto-orient",
                      :search => "-auto-orient" },
                    url: "#{POST_PHOTO_URL}/posts/:id/:style/:basename.:extension",
                    path: "#{POST_PHOTO_DIR}/posts/:id/:style/:basename.:extension"
  validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/pjpeg', 'image/x-png']
end

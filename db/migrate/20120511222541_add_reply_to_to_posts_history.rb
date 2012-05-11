class AddReplyToToPostsHistory < ActiveRecord::Migration
  def change
  	add_column :post_histories, :reply_to, :string
  end
end

class RemoveReplytoFromPostsAndPostHistories < ActiveRecord::Migration
  def up
  	remove_column :posts, :reply_to, :string
  	remove_column :post_histories, :reply_to, :string
  end

  def down
  	add_column :posts, :reply_to, :string
  	add_column :post_histories, :reply_to, :string
  end
end

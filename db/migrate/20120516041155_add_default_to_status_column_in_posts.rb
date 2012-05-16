class AddDefaultToStatusColumnInPosts < ActiveRecord::Migration
  def up
  	remove_column :posts, :status, :string
  	add_column :posts, :status, :string, :default => 'active'
  end

  def down
  	add_column :posts, :status, :string
  end
end

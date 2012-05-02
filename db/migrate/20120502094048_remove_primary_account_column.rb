class RemovePrimaryAccountColumn < ActiveRecord::Migration
  def create
    remove_column :api_accounts, :primary_account
  end
end

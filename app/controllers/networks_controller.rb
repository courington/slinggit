class NetworksController < ApplicationController
  before_filter :signed_in_user

  def index
    @api_accounts = ApiAccount.all(:conditions => ['status = "active" AND user_id = ?', current_user.id])
  end

  def create

  end

  def destroy

  end

end

class NetworksController < ApplicationController
  before_filter :signed_in_user

  def index
    @api_accounts = ApiAccount.all(:conditions => ['status = "active" AND user_id = ?', current_user.id])
  end

  def create

  end

  def destroy

  end

  def set_primary_account
    if request.post?
      if not params[:api_account_id].blank?
        api_account_id = params[:api_account_id].split('_').last
        if api_account = ApiAccount.first(:conditions => ['user_id = ? AND id = ?', current_user.id, api_account_id])
            ApiAccount.update_all("primary = 0", "primary = 1")
            api_account.update_attribute(:primary, true)
            render :text => 'Primary Account Updated', :status => 200
        end
      end
    end
  end

end

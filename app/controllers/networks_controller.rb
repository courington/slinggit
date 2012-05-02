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
    #this may seem a bit much but we only want to set the new primary if we can make sure and unset the other if there is one
    #so that there arent conflicts... if there isnt one to begin with, we just save the new one and return success
    if request.post?
      if not params[:api_account_id].blank?
        api_account_id = params[:api_account_id].split('_').last
        if new_primary_account = ApiAccount.first(:conditions => ['user_id = ? AND id = ?', current_user.id, api_account_id.to_i])
          if old_primary_account = ApiAccount.first(:conditions => ['user_id = ? AND primary_account = "t"', current_user.id])
            old_primary_account.primary_account = "f"
            if old_primary_account.save
              new_primary_account.primary_account = "t"
              if new_primary_account.save
                render :text => "#{api_account_id}", :status => 200
              end
            else
              render :text => 'error', :status => 500
            end
          else
            new_primary_account.primary_account = "t"
            if new_primary_account.save
              render :text => "#{api_account_id}", :status => 200
            else
              render :text => 'error', :status => 500
            end
          end
        else
          render :text => 'error', :status => 500
        end
      else
        render :text => 'error', :status => 500
      end
    else
      render :text => 'error', :status => 500
    end
  end

  def delete_account

  end

end

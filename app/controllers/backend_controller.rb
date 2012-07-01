class BackendController < ApplicationController
  def post_monitor
    max_days_open = system_preferences[:post_max_days_open]
    max_days_ago = Time.now.advance(:days => max_days_open.to_i * -1)
    posts = Post.find_each(:conditions => ['status = ? AND created_at < ?', STATUS_ACTIVE, max_days_ago], :select => 'id,status') do |post|
      post.update_attribute(:status, STATUS_CLOSED)
    end
    render :nothing => true
  end
end

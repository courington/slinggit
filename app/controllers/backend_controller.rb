class BackendController < ApplicationController
  def post_monitor
    max_days_open = system_preferences[:post_max_days_open]
    max_days_ago = Time.now.advance(:days => max_days_open.to_i * -1)
    posts_closed = 0
    posts = Post.find_each(:conditions => ['status = ? AND created_at < ?', STATUS_ACTIVE, max_days_ago], :select => 'id,status') do |post|
      posts_closed += 1
      post.update_attribute(:status, STATUS_CLOSED)
    end
    UserMailer.post_monitor_report(posts_closed).deliver
    render :nothing => true
  end
end

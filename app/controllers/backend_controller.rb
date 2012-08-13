class BackendController < ApplicationController
  def daily_jobs
    enabled_jobs = ['comment_notifier']

    #CLOSES POSTS THAT HAVE BEEN OPEN FOR AS LONG OR LONGER THAN THE SYSTEM PREFERENCE ALLOWS
    #STATUS: DISABLED
    #############################################

    if enabled_jobs.include? 'post_monitor'
    max_days_open = system_preferences[:post_max_days_open]
    max_days_ago = Time.now.advance(:days => max_days_open.to_i * -1)
    posts_closed = 0
    posts = Post.find_each(:conditions => ['open = ? AND status = ? AND created_at < ?', true, STATUS_ACTIVE, max_days_ago], :select => 'id,status') do |post|
      posts_closed += 1
      post.update_attribute(:open, false)
    end
    UserMailer.post_monitor_report(posts_closed).deliver

    end

    ############################################

    #SENDS AN EMAIL TO USERS WHO HAVE RECEIVED COMMENTS
    #STATUS: ENABLED
    if enabled_jobs.include? 'comment_notifier'
      #TODO WHEN I GET HOME... EDITOR IS ALL MESSED UP AT WORK
    end

    render :nothing => true
  end
end

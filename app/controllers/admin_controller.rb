class AdminController < ApplicationController
  before_filter :verify_authorization

  STATUS_UNVERIFIED = "unverified"
  STATUS_DELETED = "deleted"
  STATUS_BANNED = "banned"
  STATUS_ACTIVE = "active"

  def index
    @user = current_user
  end

  #### QUICK DATA BASE VIEW ####

  def view_database
    table_html = '<a href="/admin"> << back to index</a>'
    table_names = ActiveRecord::Base.connection.tables.delete_if { |x| x == 'schema_migrations' }
    table_names.sort.each do |name|
      table_name = "#{name.titleize.gsub(' ', '').singularize}"
      table_data = eval("#{table_name}.all")

      table_html << "<h2 style='border-bottom: solid;background-color: lightBlue;'>#{table_name}<a href='/admin/delete_db_view_data/#{table_name}' class='btn btn-large btn-primary' style='float:right'>Delete All</a></h2>"
      table_data.each do |row|
        table_html << "<ul style='border: 3px dotted'>"
        row.attributes.each do |column_name, column_data|
          table_html << "<li>#{column_name} : #{column_data}</li>"
        end
        table_html << "<li><a href='/admin/delete_db_view_record/#{table_name}_#{row.id}' class='btn btn-large btn-primary' style='font-size:20px;'>[Delete Record]</a></li></ul>"
      end

    end
    render :text => table_html
  end

  def delete_db_view_data
    if not params[:id].blank?
      data = eval("#{params[:id]}.all")
      data.each do |record|
        record.destroy
      end
    end
    redirect_to :action => 'view_database'
  end

  def delete_db_view_record
    if not params[:id].blank?
      table_name, row_id = params[:id].split('_')
      record = eval("#{table_name}.first(:conditions => ['id = ?', #{row_id}])")
      if record
        record.destroy
      end
    end
    redirect_to :action => 'view_database'
  end

  #### END QUICK DATABASE VIEW ####

  def view_users
    @users = User.paginate(page: params[:page], :per_page=>100, :select => 'id,email,name,slug,status,created_at')
  end

  def view_images
    @image_datas = []
    Post.find_each(:conditions => ['status = "active" AND photo_file_name IS NOT NULL'], :select => 'id,user_id,photo_file_name,photo_updated_at') do |post|
      @image_datas << {:image_path => post.photo.url(:medium), :post_id => post.id}
    end
  end

  def set_user_status
    user = User.first(:conditions => ['id = ?', params[:id]])
    status = params[:status]
    if not user.blank?
      if user.update_attribute(:status, status)
        if user.posts.any?
          user.posts.each do |post|
            post.update_attribute(:status, status)  
          end
        end
        flash[:success] = "User #{status}."
      else 
        flash[:error] = "User #{status} unsuccessfully"  
      end
    end
    redirect_to admin_users_path
  end

  def eradicate_all_from_image
    if request.post?
      Post.transaction do
        begin
          if not params[:post_id].blank?
            post_id = params[:post_id]
            if post = Post.first(:conditions => ['id = ? AND status != "deleted"', post_id])
              user = User.first(:conditions => ['id = ?', post.user_id])
              if not user.id == current_user.id
                if not user.is_admin?

                  #"delete" the post
                  post.update_attribute(:status, 'deleted') #remove the post

                  #suspend the user
                  user.update_attribute(:status, 'suspended')

                  #undo (delete) all posts made to any api_account
                  tweets_undon = 0
                  if not post.recipient_api_account_ids.blank? #remove the tweet
                    twitter_posts = TwitterPost.all(:conditions => ['id in (?)', post.recipient_api_account_ids.split(',')])
                    if not twitter_posts.blank?
                      twitter_posts.each do |twitter_post|
                        twitter_post.undo_post
                        tweets_undon += 1
                      end
                    end
                  end

                  #create the violation record which automatically sends an email to the user
                  ViolationRecord.create(
                      :user_id => user.id,
                      :violation => ILLICIT_PHOTO,
                      :violation_source => POST_VIOLATION_SOURCE,
                      :violation_source_id => post.id,
                      :action_taken => "post set to deleted // user.status set to suspended // tweets_undon - #{tweets_undon} // email delivered"
                  )

                  #return success and remove the photo
                  render :text => "#{params[:post_id]}", :status => 200
                else
                  render :text => "Error - That image belongs to an admin account... #{user.name}", :status => 200
                end
              else
                render :text => 'Error - That action would suspend your self.', :status => 200
              end
            else
              render :text => 'Error - Post not found or already deleted', :status => 200
            end
          else
            render :text => 'Error - No post id', :status => 200
          end
        rescue Exception => e
          raise ActiveRecord::Rollback
          render :text => e.to_s, :status => 200
        end
      end
    else
      render :text => 'Error - Invalid request', :status => 200
    end
  end

  def problem_reports
    if not params[:id].blank?
      if problem_report = ProblemReport.first(:conditions => ['id = ?', params[:id]])
        problem_report.status = 'resolved'
        problem_report.last_updated_by_user_id = current_user.id
        problem_report.save
        flash[:success] = 'Problem marked as resolved'
        redirect_to :controller => :admin, :action => :problem_reports, :id => nil #removes id from url
      end
    end
    @problem_reports = ProblemReport.all(:conditions => ['status = ?', 'open'], :order => 'status desc, created_at desc')
    if @problem_reports.length <= 0
      flash[:error] = 'No problem reports found'
      redirect_to :controller => :admin, :action => :index if not performed?
    end
  end

  def view_problem_report
    if not params[:id].blank?
      @problem_report = ProblemReport.first(:conditions => ['id = ?', params[:id]])
      if @problem_report.blank?
        alert[:error] = 'No problem report was found with that id'
        redirect_to :action => :problem_reports
      end
    end
  end

  private

  def verify_authorization
    if signed_in? and current_user.is_admin?
      return true
    else
      #we dont want people to know this exists, so redirect to 404
      redirect_to "/404.html"
    end
  end

end

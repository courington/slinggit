class TestController < ApplicationController
  before_filter :verify_authorization

  def index
    render :text => 'Your in the test controller'
  end

  def raise_exception
    if not params[:exception].blank?
      raise params[:exception]
    else
      0/0
    end
  end

  def test_file_path
    render :text => "<img src='http://localhost:3000/system/posts/photos/000/000/307/original/me_100.jpg' />"
  end

  def save_file
    tmp_dir = "#{Rails.root}/public/tmp/steve.jpg"
    @file = nil

    post = Post.new(
        :user_id => current_user.id,
        :hashtag_prefix => "steve",
        :content => "test_content",
        :price => 20,
        :location => "here",
        :photo => @file
    )

    if not post.photo_file_name.blank?
      File.delete(tmp_dir)
    end
  end

  def test_violation_creation
    ViolationRecord.create(
        :user_id => current_user.id,
        :violation => ILLICIT_PHOTO,
        :violation_source => POST_VIOLATION_SOURCE,
        :violation_source_id => 2,
        :action_taken => "post set to deleted // user.status set to suspended // tweets_undon - test // email delivered"
    )

  end

  private

  #DO NOT DELETE
  def verify_authorization
    if signed_in? and current_user.is_admin?
      return true
    else
      #we dont want people to know this exists, so redirect to 404
      redirect_to "/404.html"
    end
  end

end

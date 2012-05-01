require 'spec_helper'

describe MobileController do

  describe "GET 'user_signup'" do
    it "returns http success" do
      get 'user_signup'
      response.should be_success
    end
  end

  describe "GET 'user_login'" do
    it "returns http success" do
      get 'user_login'
      response.should be_success
    end
  end

  describe "GET 'user_logout'" do
    it "returns http success" do
      get 'user_logout'
      response.should be_success
    end
  end

  describe "GET 'user_login_status'" do
    it "returns http success" do
      get 'user_login_status'
      response.should be_success
    end
  end

  describe "GET 'create_twitter_post'" do
    it "returns http success" do
      get 'create_twitter_post'
      response.should be_success
    end
  end

  describe "GET 'delete_twitter_post'" do
    it "returns http success" do
      get 'delete_twitter_post'
      response.should be_success
    end
  end

  describe "GET 'update_twitter_post'" do
    it "returns http success" do
      get 'update_twitter_post'
      response.should be_success
    end
  end

  describe "GET 'get_user_twiiter_post_data'" do
    it "returns http success" do
      get 'get_user_twiiter_post_data'
      response.should be_success
    end
  end

  describe "GET 'get_slinggit_twitter_post_data'" do
    it "returns http success" do
      get 'get_slinggit_twitter_post_data'
      response.should be_success
    end
  end

  describe "GET 'get_user_api_accounts'" do
    it "returns http success" do
      get 'get_user_api_accounts'
      response.should be_success
    end
  end

end

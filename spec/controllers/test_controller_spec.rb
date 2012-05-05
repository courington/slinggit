require 'spec_helper'

describe TestController do

  describe "GET 'db_view'" do
    it "returns http success" do
      get 'db_view'
      response.should be_success
    end
  end

end

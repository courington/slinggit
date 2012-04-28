require 'spec_helper'

describe "PostPages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe "post creation" do
    before { visit new_post_path }

    describe "with invalid information" do

      it "should not create a post" do
        expect { click_button "Post" }.should_not change(Post, :count)
      end

      describe "error messages" do
        before { click_button "Post" }
        it { should have_content('error') } 
      end
    end

    describe "with valid information" do

      before { fill_in_post }
      it "should create a post" do
        expect { click_button "Post" }.should change(Post, :count).by(1)
      end
    end
  end

  describe "post destruction" do
    before { FactoryGirl.create(:post, user: user) }

    describe "as correct user" do
      before { visit user_path(user) }

      it "should delete a post" do
        expect { click_link "delete" }.should change(Post, :count).by(-1)
      end
    end
  end

  describe "post edit" do
  	let(:p1) { FactoryGirl.create(:post, user: user, content: "Foo") }
  	before { visit edit_post_path(p1) }

  	describe "page" do
  		it { should have_selector('h1', text: "Update your post") }
  	end

  	describe "with invalid information" do
  	  let(:new_content)  { " " }
      before do
        fill_in "Content",             with: new_content
        click_button "Save changes"
      end
      it { should have_content('error') }
    end

    describe "with valid information" do
     let(:new_content)  { "New content" }
      before do
        fill_in "Content",             with: new_content
        click_button "Save changes"
      end

      it { should have_selector('div.alert.alert-success') }
      specify { p1.reload.content.should  == new_content }
    end	
  end	

end

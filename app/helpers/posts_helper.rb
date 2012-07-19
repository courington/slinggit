module PostsHelper

	def generate_twitter_link twitter_account, post, user
		if not twitter_account.blank?
		  # Create the instance twitter_post varialbe
          @twitter_post = TwitterPost.first(conditions: ['post_id = ? AND api_account_id = ? ', post.id, twitter_account.id], order: "created_at DESC")
          if @twitter_post.blank?
          	# If it's blank, find the first twitter_post associated with this post.  We can return nil
          	# if one isn't found.  The UI is checking for that. This could happen if a user has multiple
          	# twitter accounts and only posts to a secondary one.
            @twitter_post = TwitterPost.first(conditions: ['post_id = ? AND user_id = ?', @post.id, @user.id], order: "created_at DESC")
          end
        else
          # If the twitter_acount passed in is nil, first try and find a twitter_post associated with 
          # this post, and if found, try and find the twitter_account it was posted to.  This would have
          # to be the slinggit handle as at least one of the user's twitter accounts needs to be primary.
          @twitter_post = TwitterPost.first(conditions: ['post_id = ? AND user_id = ?', post.id, user.id], order: "created_at DESC")
          @twitter_account = ApiAccount.first(:conditions => ['id = ?', @twitter_post.api_account_id], :select => 'user_name') unless @twitter_post == nil
        end
	end

	def generate_facebook_link facebook_account, post, user
		if not facebook_account.blank?
		  # We'll need to truncate the id as it includes extra characters not needed in the link.
	      @facebook_truncated_id = nil
	      @facebook_post = FacebookPost.first(conditions: ['post_id = ? AND api_account_id = ? ', post.id, facebook_account.id], order: "created_at DESC")
	      if @facebook_post.blank?
	      	# In the rare case where a user might have more than one facebook account and they have posted to 
	      	# only their secondary, we can check for that here.
	      	@facebook_post = FacebookPost.first(conditions: ['post_id = ? AND user_id = ? ', post.id, user.id], order: "created_at DESC")
	      end
	      if @facebook_post != nil and @facebook_post.facebook_post_id != nil
	        delims = @facebook_post.facebook_post_id.to_s.split("_")
	        @facebook_truncated_id = delims[1]
	      end
	    else
	      # We would fall into this block if we ever allow the user to post to some 
	      # kind of slinggit facebook handle and the user has only posted to that and 
	      # not registered a facebook account of their own with slinggit.
	      @facebook_truncated_id = nil
	      # See if a facebook post is associated with this posts and find the slinggit handle it's associated with.
	      @facebook_post = FacebookPost.first(conditions: ['post_id = ? AND user_id = ? ', post.id, user.id], order: "created_at DESC")
	      # if the face_book account passed in was nil, we can override it if we find a facebook_post associated with this account
	      @facebook_account = ApiAccount.first(:conditions => ['id = ?', @facebook_post.api_account_id], :select => 'user_name') unless @facebook_post == nil
	      if @facebook_post != nil and @facebook_post.facebook_post_id != nil
	        delims = @facebook_post.facebook_post_id.to_s.split("_")
	        @facebook_truncated_id = delims[1]
	      end
	    end
	end
end
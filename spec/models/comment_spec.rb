# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  body       :text
#  post_id    :integer
#  user_id    :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe Comment do
  pending "add some examples to (or delete) #{__FILE__}"
end

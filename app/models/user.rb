# == Schema Information
#
# Table name: users
#
#  id              :integer         not null, primary key
#  user_name            :string(255)
#  email           :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  password_digest :string(255)
#  remember_token  :string(255)
#  admin           :boolean         default(FALSE)
#  twitter_atoken  :string(255)
#  twitter_asecret :string(255)
#

class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :password_confirmation, :remember_me, :twitter_atoken, :twitter_asecret
  has_secure_password
  has_many :posts, dependent: :destroy

  before_save { |user| user.email = email.downcase }
  before_save :create_remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }

  validates_format_of :name, :with =>  /^[a-z0-9_-]+$/i, :message => 'can only contain letters, numbers, underscores and dashes'
  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :maximum => 50

  validates :password, length: { minimum: 6 }
  validates_presence_of :password_confirmation


  def twitter_authorized?
    !twitter_atoken.blank? && !twitter_asecret.blank?
  end

  private

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

end

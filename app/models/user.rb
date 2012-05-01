# == Schema Information
#
# Table name: users
#
#  id              :integer         not null, primary key
#  name            :string(255)
#  email           :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  password_digest :string(255)
#  remember_token  :string(255)
#  mobile_remember_token  :string(255)
#  admin           :boolean         default(FALSE)
#  twitter_atoken  :string(255)
#  twitter_asecret :string(255)
#

class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :password_confirmation, :remember_me, :twitter_atoken, :twitter_asecret
  has_secure_password
  has_many :posts, dependent: :destroy

  before_save :downcase_attributes
  before_save :create_remember_token

  # Allows letters, numbers and underscore
  VALID_USERNAME_REGEX = /\A[a-z0-9_]{,20}\z/i
  validates :name, presence: true, length: {maximum: 50},
            format: {with: VALID_USERNAME_REGEX},
            uniqueness: {case_sensitive: false}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validates :password, length: {minimum: 6}
  validates :password_confirmation, presence: true


  def twitter_authorized?
    !twitter_atoken.blank? && !twitter_asecret.blank?
  end

  private

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end

  def downcase_attributes
    self.email = email.downcase
    self.name = name.downcase
  end

end

# == Schema Information
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  name                :string(255)
#  email               :string(255)
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  password_digest     :string(255)
#  remember_token      :string(255)
#  admin               :boolean         default(FALSE)
#  status              :string(255)     default("active")
#  password_reset_code :string(255)
#

class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :password_confirmation, :remember_me, :twitter_atoken, :twitter_asecret, :status
  has_secure_password
  has_many :posts, dependent: :destroy
  # not making comments dependent: :destroy because we may still want comments associated with posts
  # even if the user is destroyed.  If this is wrong, let's change it.
  has_many :comments

  before_save :downcase_attributes
  before_save :create_remember_token
  after_create :create_post_limitation_record

  # Allows letters, numbers and underscore
  VALID_USERNAME_REGEX = /\A[a-z0-9_-]{,20}\z/i
  validates :name, presence: true, length: {maximum: 20},
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

  def primary_twitter_account
    ApiAccount.first(:conditions => ['user_id = ? AND status = "primary"', self.id])
  end

  def email_is_verified?
    self.email_activation_code.blank?
  end

  private

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end

  def downcase_attributes
    self.email = email.downcase
    self.name = name.downcase
  end

  def create_post_limitation_record
    UserLimitation.create(
        :user_id => self.id,
        :limitation_type => 'posts',
        :user_limit => 10,
        :frequency => '24',
        :frequency_type => 'hours',
        :active => true
    )
  end

end

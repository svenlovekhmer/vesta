class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_one :profile
  has_many :clients
  has_many :missions, through: :clients
  has_many :step_templates, dependent: :destroy
  has_one :gmail_connection, dependent: :destroy

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user.present?

    user = find_or_initialize_by(email: auth.info.email)
    user.provider = auth.provider
    user.uid = auth.uid
    user.password = Devise.friendly_token[0, 20] if user.new_record?
    user
  end
end

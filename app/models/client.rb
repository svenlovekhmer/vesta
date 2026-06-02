class Client < ApplicationRecord
  belongs_to :user
  has_many :missions, dependent: :destroy

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true, format: { with: /\A\+?[0-9\s\-]+\z/, message: "doit être un numéro de téléphone valide" }
end

class GmailConnection < ApplicationRecord
  belongs_to :user

  validates :email, uniqueness: true
end

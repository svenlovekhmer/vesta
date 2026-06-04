class DecisionLog < ApplicationRecord
  belongs_to :mission

  has_many :mission_step_blockers, dependent: :nullify

  validates :title, presence: true
  validates :owner_type, presence: true

  enum :owner_type, { client: "client", provider: "provider", third_party: "third_party" }, prefix: :owned_by
end

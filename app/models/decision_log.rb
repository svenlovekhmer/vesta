class DecisionLog < ApplicationRecord
  belongs_to :mission

  has_many :mission_step_blockers, dependent: :destroy

  enum :owner_type, { client: "client", provider: "provider", third_party: "third_party" }, prefix: :owned_by
end

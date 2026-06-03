class DecisionLog < ApplicationRecord
  belongs_to :mission

  enum :owner_type, { client: "client", provider: "provider", third_party: "third_party" }, prefix: :owned_by
end

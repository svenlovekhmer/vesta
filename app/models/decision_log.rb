class DecisionLog < ApplicationRecord
  belongs_to :mission

  has_many :mission_step_blockers, dependent: :nullify
  has_many :decision_log_documents, dependent: :destroy
  has_many :documents, through: :decision_log_documents

  validates :title, presence: true
  validates :owner_type, presence: true

  enum :owner_type, { client: "client", provider: "provider", third_party: "third_party" }, prefix: :owned_by
end

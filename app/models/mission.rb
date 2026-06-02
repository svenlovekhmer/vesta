class Mission < ApplicationRecord
  belongs_to :mission_status
  belongs_to :step_template, optional: true # temporary, to be removed when the step templatating will be implemented
  belongs_to :client

  has_many :steps, dependent: :destroy
  has_many :decision_logs, dependent: :destroy

  validates :title, presence: true
end

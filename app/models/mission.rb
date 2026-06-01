class Mission < ApplicationRecord
  belongs_to :mission_status
  belongs_to :step_template
  belongs_to :client
  has_many :steps
  has_many :decision_logs
end

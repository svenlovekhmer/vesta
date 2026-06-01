class Mission < ApplicationRecord
  belongs_to :mission_status
  belongs_to :step_template
  belongs_to :client

  validates :title, presence: true
end

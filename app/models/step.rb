class Step < ApplicationRecord
  belongs_to :step_status
  belongs_to :mission
end

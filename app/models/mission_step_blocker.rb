class MissionStepBlocker < ApplicationRecord
  belongs_to :mission
  belongs_to :step
  belongs_to :decision_log

  enum :blocking_status, { blocking: "blocking", warning: "warning", resolved: "resolved" }
end

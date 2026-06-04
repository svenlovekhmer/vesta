class MissionStepBlocker < ApplicationRecord
  belongs_to :mission
  belongs_to :step, optional: true
  belongs_to :decision_log, optional: true

  enum :blocking_status, { blocking: "blocking", warning: "warning", resolved: "resolved" }
end

class TightenDecisionLogsAndStepBlockers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :decision_logs, :status, from: nil, to: "pending"

    execute <<~SQL
      UPDATE decision_logs
      SET status = 'pending'
      WHERE status IS NULL
    SQL

    change_column_null :decision_logs, :status, false
    execute <<~SQL
      DELETE FROM mission_step_blockers
      WHERE decision_log_id IS NULL
    SQL
    change_column_null :mission_step_blockers, :decision_log_id, false
  end
end

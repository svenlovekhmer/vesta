class RemoveSourceFieldsFromDecisionLogs < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :decision_logs,
      name: "decision_logs_source_type_check",
      if_exists: true
    remove_column :decision_logs, :source_id, :uuid if column_exists?(:decision_logs, :source_id)
    remove_column :decision_logs, :source_type, :string if column_exists?(:decision_logs, :source_type)
  end
end

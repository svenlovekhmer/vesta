class AddSnapshotTitlesToBlocersAndMakeStepFksNullable < ActiveRecord::Migration[8.1]
  def change
    add_column :mission_step_blockers, :step_title, :string
    add_column :mission_step_blockers, :decision_log_title, :string

    change_column_null :mission_step_blockers, :step_id, true
    change_column_null :mission_step_blockers, :decision_log_id, true
  end
end

class AddMissionAlignmentItems < ActiveRecord::Migration[8.1]
  def change
    rename_column :decision_logs, :status, :category
    rename_column :decision_logs, :content, :description

    add_column :decision_logs, :title, :string
    add_column :decision_logs, :source_type, :string
    add_column :decision_logs, :source_id, :uuid

    execute <<~SQL
      UPDATE decision_logs
      SET category = CASE category
        WHEN 'agreed' THEN 'decided'
        WHEN 'pending' THEN 'pending'
        WHEN 'unclear' THEN 'unclear'
        ELSE 'decided'
      END
    SQL

    add_check_constraint :decision_logs,
      "category IN ('decided', 'pending', 'unclear')",
      name: "decision_logs_category_check"

    add_check_constraint :decision_logs,
      "source_type IS NULL OR source_type IN ('message', 'email', 'document', 'manual', 'ai')",
      name: "decision_logs_source_type_check"

    create_table :mission_alignment_items do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :source_decision_log,
        null: false,
        foreign_key: { to_table: :decision_logs }

      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "active"

      t.string :owner_type
      t.references :owner, foreign_key: { to_table: :users }

      t.date :due_date
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :mission_alignment_items,
      "status IN ('active', 'resolved', 'archived')",
      name: "mission_alignment_items_status_check"
    add_check_constraint :mission_alignment_items,
      "owner_type IS NULL OR owner_type IN ('client', 'provider', 'third_party')",
      name: "mission_alignment_items_owner_type_check"

    create_table :mission_step_blockers do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :step, null: false, foreign_key: true
      t.references :alignment_item,
        null: false,
        foreign_key: { to_table: :mission_alignment_items }

      t.string :blocking_status, null: false, default: "blocking"
      t.datetime :resolved_at

      t.timestamps
    end

    add_check_constraint :mission_step_blockers,
      "blocking_status IN ('blocking', 'warning', 'resolved')",
      name: "mission_step_blockers_blocking_status_check"
  end
end

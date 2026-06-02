class SimplifyDecisionLogsAlignmentModel < ActiveRecord::Migration[8.1]
  def change
    # 1. decision_logs devient la table centrale
        remove_check_constraint :decision_logs,
          name: "decision_logs_category_check",
          if_exists: true
        rename_column :decision_logs, :category, :status if column_exists?(:decision_logs, :category)
        add_column :decision_logs, :owner_type, :string unless column_exists?(:decision_logs, :owner_type)
        add_reference :decision_logs, :owner, foreign_key: { to_table: :users } unless column_exists?(:decision_logs, :owner_id)
        add_column :decision_logs, :due_date, :date unless column_exists?(:decision_logs, :due_date)
        add_column :decision_logs, :position, :integer, default: 0, null: false unless column_exists?(:decision_logs, :position)

        execute <<~SQL
          UPDATE decision_logs
          SET status = CASE status
            WHEN 'decided' THEN 'decided'
            WHEN 'pending' THEN 'pending'
            WHEN 'unclear' THEN 'pending'
            ELSE 'pending'
          END
        SQL

        add_check_constraint :decision_logs,
          "status IN ('decided', 'pending')",
          name: "decision_logs_status_check",
          if_not_exists: true

        add_check_constraint :decision_logs,
          "owner_type IS NULL OR owner_type IN ('client', 'provider', 'third_party')",
          name: "decision_logs_owner_type_check",
          if_not_exists: true

        # 2. Récupérer les infos utiles depuis mission_alignment_items
        if table_exists?(:mission_alignment_items)
          execute <<~SQL
            UPDATE decision_logs dl
            SET
              owner_type = COALESCE(dl.owner_type, mai.owner_type),
              owner_id = COALESCE(dl.owner_id, mai.owner_id),
              due_date = COALESCE(dl.due_date, mai.due_date),
              position = COALESCE(dl.position, mai.position)
            FROM mission_alignment_items mai
            WHERE mai.source_decision_log_id = dl.id
          SQL
        end

        # 3. mission_step_blockers pointe maintenant vers decision_logs
        if table_exists?(:mission_step_blockers)
          add_reference :mission_step_blockers,
            :decision_log,
            foreign_key: true unless column_exists?(:mission_step_blockers, :decision_log_id)
          if column_exists?(:mission_step_blockers, :alignment_item_id) && table_exists?(:mission_alignment_items)

            execute <<~SQL
              UPDATE mission_step_blockers msb
              SET decision_log_id = mai.source_decision_log_id
              FROM mission_alignment_items mai
              WHERE msb.alignment_item_id = mai.id
            SQL
          end
          remove_foreign_key :mission_step_blockers,
            column: :alignment_item_id if foreign_key_exists?(:mission_step_blockers, column: :alignment_item_id)
          remove_reference :mission_step_blockers,
            :alignment_item,
            index: true if column_exists?(:mission_step_blockers, :alignment_item_id)
        end

        # 4. Supprimer l’ancienne table devenue inutile
        drop_table :mission_alignment_items if table_exists?(:mission_alignment_items)
  end
end

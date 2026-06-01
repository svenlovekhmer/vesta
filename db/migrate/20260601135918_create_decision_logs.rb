class CreateDecisionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :decision_logs do |t|
      t.string :status
      t.text :content
      t.string :decided_by
      t.date :decided_at
      t.references :mission, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class UpdateDocumentsAndAddDecisionLogDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :documents, :mission, null: false, foreign_key: true
    change_column_null :documents, :step_id, true
    remove_column :documents, :file_url, :string
    remove_column :documents, :file_type, :string

    create_table :decision_log_documents do |t|
      t.references :decision_log, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.timestamps
    end
    add_index :decision_log_documents, [:decision_log_id, :document_id], unique: true
  end
end

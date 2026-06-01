class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :name
      t.string :file_url
      t.string :file_type
      t.references :step, null: false, foreign_key: true

      t.timestamps
    end
  end
end

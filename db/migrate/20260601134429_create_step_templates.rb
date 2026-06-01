class CreateStepTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :step_templates do |t|
      t.string :name
      t.string :description
      t.string :is_default
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

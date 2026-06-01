class CreateStepTemplateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :step_template_items do |t|
      t.string :title
      t.string :description
      t.string :position
      t.references :step_template, null: false, foreign_key: true

      t.timestamps
    end
  end
end

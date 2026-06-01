class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.string :title
      t.string :portal_token
      t.references :mission_status, null: false, foreign_key: true
      t.references :step_template, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end

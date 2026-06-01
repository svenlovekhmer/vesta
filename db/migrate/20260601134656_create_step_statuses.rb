class CreateStepStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :step_statuses do |t|
      t.string :title

      t.timestamps
    end
  end
end

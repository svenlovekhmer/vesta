class CreateMissionStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_statuses do |t|
      t.string :title

      t.timestamps
    end
  end
end

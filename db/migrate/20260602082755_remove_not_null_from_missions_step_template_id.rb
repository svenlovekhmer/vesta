class RemoveNotNullFromMissionsStepTemplateId < ActiveRecord::Migration[8.1]
  def change
    change_column_null :missions, :step_template_id, true
  end
end

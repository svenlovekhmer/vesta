class AddSourceToDecisionLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :decision_logs, :source, :string
  end
end

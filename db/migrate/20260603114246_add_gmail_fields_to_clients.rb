class AddGmailFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :gmail_summary, :text
    add_column :clients, :gmail_last_synced_at, :datetime
    add_column :clients, :gmail_messages_count, :integer
  end
end

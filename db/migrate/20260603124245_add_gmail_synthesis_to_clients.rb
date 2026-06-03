class AddGmailSynthesisToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :gmail_synthesis, :text
  end
end

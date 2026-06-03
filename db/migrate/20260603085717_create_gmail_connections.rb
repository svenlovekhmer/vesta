class CreateGmailConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :gmail_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end

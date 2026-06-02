class AddPhoneNumberToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :phone_number, :string
  end
end

class CreateTxAddresses < ActiveRecord::Migration
  def change
    create_table :tx_addresses do |t|
      t.references :user, index: true
      t.string :address
      t.string :nickname

      t.timestamps
    end
  end
end

class RemoveTxAddress < ActiveRecord::Migration
  def change
    drop_table :tx_addresses
  end
end

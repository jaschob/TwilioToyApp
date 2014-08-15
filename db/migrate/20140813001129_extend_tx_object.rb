class ExtendTxObject < ActiveRecord::Migration
  def change
    change_table :coin_transactions do |t|
      t.string :address, { null: false }
      t.integer :confirmations
      t.datetime :blocktime
      t.datetime :time
      t.datetime :timereceived
    end
  end
end

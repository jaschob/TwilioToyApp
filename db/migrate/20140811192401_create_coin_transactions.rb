class CreateCoinTransactions < ActiveRecord::Migration
  def change
    create_table :coin_transactions do |t|
      t.string :txid, { null: false }
      t.references :user, index: true
      t.string :category
      t.decimal :amount
      t.decimal :fee
      t.string :blockhash
      t.string :comment
      t.boolean :user_notified

      t.timestamps

      t.index [:txid, :user_id], unique: true
    end
  end
end

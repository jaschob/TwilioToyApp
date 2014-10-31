class RemoveDynamicsFromCoinTransactions < ActiveRecord::Migration
  def change
    remove_column :coin_transactions, :address, :string
    remove_column :coin_transactions, :category, :string
    remove_column :coin_transactions, :amount, :string
    remove_column :coin_transactions, :fee, :string
    remove_column :coin_transactions, :confirmations, :string
    remove_column :coin_transactions, :blockhash, :string
    remove_column :coin_transactions, :blocktime, :string
    remove_column :coin_transactions, :time, :string
    remove_column :coin_transactions, :timereceived, :string
    remove_column :coin_transactions, :comment, :string
    remove_column :coin_transactions, :confirmations, :string
  end
end

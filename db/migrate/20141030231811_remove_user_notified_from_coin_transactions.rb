class RemoveUserNotifiedFromCoinTransactions < ActiveRecord::Migration
  def change
    remove_column :coin_transactions, :user_notified, :string
  end
end

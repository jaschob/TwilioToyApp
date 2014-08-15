class ExpandUserFields < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.remove :email           # no need in a toy app!
      
      t.string :phone
      t.string :notify_tx
    end
  end
end

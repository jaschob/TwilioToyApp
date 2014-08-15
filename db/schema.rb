# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140815154622) do

  create_table "coin_transactions", force: true do |t|
    t.string   "txid",                       null: false
    t.integer  "user_id"
    t.string   "category"
    t.decimal  "amount"
    t.decimal  "fee"
    t.string   "blockhash"
    t.string   "comment"
    t.boolean  "user_notified"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "address",       default: "", null: false
    t.integer  "confirmations"
    t.datetime "blocktime"
    t.datetime "time"
    t.datetime "timereceived"
  end

  add_index "coin_transactions", ["txid", "user_id"], name: "index_coin_transactions_on_txid_and_user_id", unique: true
  add_index "coin_transactions", ["user_id"], name: "index_coin_transactions_on_user_id"

  create_table "users", force: true do |t|
    t.string   "username"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
    t.string   "notify_tx"
  end

end

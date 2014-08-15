require 'test_helper'
require 'coin_helper'

class UserTest < TestWithCoinSetup
  test "phone number normalization" do
    one = users(:one)
    one.phone = "(555) 123-4567"
    one.valid?                  # forces validation -> normalization
    assert_equal "+15551234567", one.phone,
    "phone number not in expected format!"
  end

  # before we test a lot, ensure every user has 100 Satoshi
  test "btc_setup" do
    users = [:one, :two, :three, :four].collect { |s| users(s) }
    users.each do |user|
      assert_equal Coin::Amount.new("0.00000100"),
                   user.coin_balance
    end
  end

  # can't allow a username to change after initial creation
  test "username modification" do
    one = users(:one)
    assert one.valid?, "test user one not valid!"

    one.username = "one_modified"
    assert one.invalid?
    assert one.errors.include? :username
  end
end

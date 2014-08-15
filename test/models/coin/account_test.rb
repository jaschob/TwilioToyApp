require 'test_helper'
require 'coin_helper'

class AccountTest < TestWithCoinSetup
  test "new user donation amount" do
    assert @app.new_user_donation_amount.kind_of? BigDecimal
  end

  test "account actions" do
    amt_zero = BigDecimal.new("0.00000000")
    amt_1_satoshi = BigDecimal.new("0.00000001")
    amt_100_satoshi = BigDecimal.new("0.00000100")

    assert Coin::Account.core
    assert Coin::Account.core.kind_of? Coin::Account

    one = users :one
    two = users :two
    assert_equal amt_100_satoshi, one.coin_balance
    assert_equal amt_100_satoshi, one.coin_balance

    one.coin_account.move(amt_1_satoshi, "two")
    one.coin_account.move(amt_1_satoshi, two)
    one.coin_account.move(amt_1_satoshi, two.coin_account)

    assert_equal BigDecimal.new("0.00000097"), one.coin_balance
    assert_equal BigDecimal.new("0.00000103"), two.coin_balance

    # check access/actions with the core account
    core_account = Coin::Account.core
    assert_equal "", core_account.name
    Coin::Account.core do |a|
      a.move amt_1_satoshi, two
    end
    assert_equal BigDecimal.new("0.00000097"), one.coin_balance
    assert_equal BigDecimal.new("0.00000104"), two.coin_balance

    # check things that shouldn't work
    assert_raises ArgumentError do # can't move negative amounts
      one.coin_account.move(BigDecimal.new("-42"), two)
    end
    assert_raises ArgumentError do # can't move to self
      one.coin_account.move(amt_1_satoshi, one)
    end
    assert_raises ArgumentError do # can't overdraw
      one.coin_account.move(amt_100_satoshi, two)
    end
  end
end

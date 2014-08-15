require 'test_helper'

# A common superclass that sets up all accounts with 100 Satoshi. It
# also sets up @logger and @app members
class TestWithCoinSetup < ActiveSupport::TestCase
  def setup
    @logger = Rails.logger
    @app = Rails.application
    
    # first, put all coins back in the core account
    rpc = Coin::RPC.new
    accounts = rpc.listaccounts
    accounts.each do |account, balance|
      unless account == ""
        if balance > 0
          rpc.move account, "", balance
        elsif balance < 0
          @logger.debug "moving negative amount"
          rpc.move "", account, balance * -1
        end
      end
    end

    # then distribute 100 Satoshi to each of the test accounts
    accounts.select {|k, v| k != ""}.each do |account, balance|
      rpc.move "", account, BigDecimal.new("0.00000100")
    end
  end

  def teardown
    #@logger.debug "Tearing down a test case"
  end
end

require 'test_helper'

class TransactionsControllerTest < ActionController::TestCase
  test "should get balance" do
    get :balance
    assert_response :success
  end

  test "should get send" do
    get :send
    assert_response :success
  end

  test "should get status" do
    get :status
    assert_response :success
  end

end

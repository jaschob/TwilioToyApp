class TransactionsController < ApplicationController
  before_filter :require_user
  before_action :set_user, :set_account

  # GET /transactions/x334455ss222211
  def show
    begin
      @tx = Coin::Transaction.new(txid: params[:id],
                                  user: @user).load_rpc_data!
    rescue Coin::RPC::RPCError
      # TODO: for known error code (-5) render invalid TX view
    end
  end

  # POST
  def create
  end

  # GET transactions/recent/5
  def recent
  end

  private

  def set_user
    @user = current_user
  end

  def set_account
    @account = @user.coin_account
  end
end

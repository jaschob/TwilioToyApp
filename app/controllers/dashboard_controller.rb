class DashboardController < ApplicationController
  before_filter :require_user
  before_action :set_user, :set_account

  def display
    poll()                 # sets @best_block and @activity
    @twilio_number = Rails.application.twilio_number
    @known_balances = Coin::Account.all_balances
    @balance = @account.balance
    @other_users = User.all.reject {|u| u == current_user}.sort do |a, b|
      a.username <=> b.username
    end
    @recent_tx = @account.recent_tx.sort do |a, b|
      b.time <=> a.time
    end
  end

  private

  def set_user
    @user = current_user
  end

  def set_account
    @account = @user.coin_account
  end
end

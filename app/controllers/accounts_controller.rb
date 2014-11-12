class AccountsController < ApplicationController
  before_filter :require_user
  before_action :set_account

  respond_to :html, :json, :twiml

  def show
  end

  def recenttx
    p = recenttx_params
    opts = {}
    opts[:count] = p[:count] if p[:count].kind_of?(Numeric) && p[:count] > 0

    @recent_tx = @account.recent_tx(opts).sort do |a, b|
      b.time <=> a.time
    end
  end

  # POST only
  def sendfrom
    params = sendfrom_params

    amount = BigDecimal.new(params[:amount])
    recipient = User.find_by(id: params[:recipient])

    # initiate the send
    current_user.coin_account.txsend amount, recipient

    # render a response appropriate to the format
    respond_to do |format|
      format.json { render json: {
          status: "ok",
          message: "Transfer of #{view_context.amount_for_display(amount)} " +
                   "to #{recipient.username} has been transmitted to the " +
                   "bitcoin network."
        }
      }
      format.twiml {
        render "sendfrom_#{twilio_type}.twiml",
                locals: {
                  :amount => amount,
                  :recipient => recipient
                } if twilio_type
      }
    end
  end

  private

  def recenttx_params
    params.permit(:count)
  end

  def sendfrom_params
    params.permit(:recipient, :amount)
  end

  def set_account
    @account = current_user.coin_account
  end

  def account_params
    params.permit(:with_html)
  end

end

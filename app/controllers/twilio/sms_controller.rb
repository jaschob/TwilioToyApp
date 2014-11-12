module Twilio
  class SmsController < ApplicationController
    before_filter :require_user

    # dispatch table based on what the SMS looked like
    SMS_DISPATCH = [
      {
        regex:   /\A \s* (?:get)? balance \s* \z/ix,
        handler: :balance_command
      },
      {
        regex:   /\A \s* send \s+ (\S+) \s+ ([0-9.]+)\s* \z/ix,
        handler: :send_command
      }
    ]

    # Handles the SMS message by redirecting to the appropriate controller and
    # action.
    def incoming
      body = params[:Body]

      respond_to do |format|
        format.twiml {
          SMS_DISPATCH.detect do |config|

            md = config[:regex].match(body)
            if md
              self.send config[:handler], *md
              return
            end

          end

          # no hit: render generic message
          render "bad_command"
        }
      end
    end

    # User has asked for their balance.
    def balance_command(text)
      redirect_to account_path("balance", format: :twiml)
    end

    # User has asked to send money to someone
    def send_command(text, recipient, amount)
      user = User.find_by(username: recipient)
      if user
        redirect_to sendfrom_account_path(format: :xml,
                                          amount: amount,
                                          recipient: user.id)
        # TODO allow direct bitcoin address here too
      else
        render "bad_send_recipient", locals: { :bad_user => recipient }
      end
    end
  end
end

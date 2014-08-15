class TwilioController < ApplicationController
  before_filter :require_user

  # dispatch table based on what the SMS looked like
  SMS_DISPATCH = [
    {
      regex: /\A \s* (?:get)? balance \s* \z/ix,
      action: lambda do |c, text|
        c.redirect_to c.account_path(format: :xml)
      end
    },
    {
      regex: /\A \s* send \s+ (\S+) \s+ ([0-9.]+)\s* \z/ix,
      action: lambda do |c, text, recipient, amount|
        user = User.find_by(username: recipient)
        if user
          c.redirect_to c.sendfrom_account_path(format: :xml,
                                                amount: amount,
                                                recipient: user.id)
        end
      end
    }
  ]

  # This action is configured in Twilio as the incoming URL. The parameter
  # twilio_type determines whether we're handling an SMS or a voice call.
  def incoming
    if twilio_sms_type?
      dispatch_sms
    elsif twilio_voice_type?
      voice_menu_prompt
    end
  end

  # Renders a voice menu prompt. Right now, all a user can select is 1 (to hear
  # their balance
  def voice_menu_prompt
    respond_to do |format|
      format.xml {
        render "menu_voice.twiml"
      }
    end
  end

  # Handles the results from the voice menu by redirecting to the appropriate
  # controller and action.
  def dispatch_voice
    digits = params[:Digits]

    respond_to do |format|
      format.xml {
        case digits
        when "1"
          redirect_to account_path(format: :xml)
        else
          render "badcommand_voice.twiml", :locals => { :command => digits }
        end
      }
    end
  end

  # Handles the SMS message by redirecting to the appropriate controller and
  # action.
  def dispatch_sms
    body = params[:Body]

    respond_to do |format|
      format.xml {
        SMS_DISPATCH.any? do |d|
          (md = d[:regex].match(body)) && d[:action].call(self, *md)
        end or render "badcommand_sms.twiml"
      }
    end
  end
end

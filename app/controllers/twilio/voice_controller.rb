module Twilio
  class VoiceController < ApplicationController
    before_filter :require_user

    ##################################################################
    ### Menus
    def menu
      case
      when params[:Digits] == "0"
        render 'hangup'

      when params[:Digits] == "1"
        redirect_to(twilio_voice_path "menu_network", format: :twiml)

      when params[:Digits] == "2"
        redirect_to(account_path format: :twiml)

      end

      # check if user entered an unrecognized digit
      if ! params[:Digits].blank? then @bad_digit = params[:Digits] end

    end

    # Secondary menu to hear about the bitcoin network state.
    def menu_network
      case
      when params[:Digits] == "1"
        redirect_to(twilio_voice_path "chainheight", format: :twiml)

      when params[:Digits] == "2"
        redirect_to(twilio_voice_path "difficulty", format: :twiml)

      when params[:Digits] == "3"
        redirect_to(twilio_voice_path "hashrate", format: :twiml)

      when params[:Digits] == "4"
        redirect_to(twilio_voice_path format: :twiml)

      end

      # check if user entered an unrecognized digit
      if ! params[:Digits].blank? then @bad_digit = params[:Digits] end
    end

    ##################################################################
    ### Responses
    def chainheight
      fetch_mininginfo
    end

    def difficulty
      fetch_mininginfo
    end

    def hashrate
      fetch_mininginfo
    end

    private

    def fetch_mininginfo
      @info = Coin::RPC.new.getmininginfo
    end
  end
end

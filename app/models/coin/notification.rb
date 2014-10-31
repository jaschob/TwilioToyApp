module Coin
  class Notification
    METHODS = {
      :sms => :notify_by_sms,
      :voice => :notify_by_voice
    }

    attr_reader :tx, :method

    def initialize(opts)
      @tx = opts[:tx] or raise ArgumentError, "TX option required via :tx!"
      @method = METHODS[opts[:method]]
    end

    def run
      @tx = tx.load_rpc_data!
      @method and self.send @method
    end

    def notify_by_sms
      text = ApplicationController.new
        .render_to_string(:template => 'transactions/show',
                          :formats => [:text],
                          :locals => { :@tx => tx })

      client = Rails.application.twilio_client
      client.account.messages.create(:body => text,
                                     :to   => tx.user.phone,
                                     :from => Rails.application.twilio_number)
    end

    def notify_by_voice
      raise NotImplementedError, "Voice notifications are a TODO item."
    end
  end
end

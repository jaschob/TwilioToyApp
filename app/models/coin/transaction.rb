module Coin
  # we store transactions not so much for the important information, but to
  # keep track of changes for user notifications etc. The actual transaction
  # information (amount, fees, etc.) is queried through the JSON-RPC interface.
  class Transaction < ActiveRecord::Base
    # Fields that are mapped from a JSON-RPC call to bitcoind into the model.
    ALLOWED_FIELDS = [:address, :category, :amount, :fee,
                      :confirmations, :blockhash, :blocktime,
                      :time, :timereceived, :comment, :confirmations]
    ALLOWED_FIELDS_HEADER = ALLOWED_FIELDS.reject do |f|
      [:address, :category, :amount, :fee].include? f
    end

    belongs_to :user

    # hook up callbacks
    after_create :set_defaults

    # Called via bin/rails runner whenever bitcoind is notified of a new
    # transaction - must be configured via walletnotify option to bitcoind
    def Transaction.txnotify(txid)
      rpc = RPC.new
      tx_data = rpc.gettransaction txid

      Rails.logger.info "Processing bitcoind notification for tx #{txid}"
      tx_data['details'].each do |tx_account_data|
        account_name = tx_account_data['account']
        Rails.logger.debug "Account name is #{account_name}"
        # find the user by the account name
        user = account_name.blank? ? nil :
          User.find_by(username: account_name)

        if user
          # find/create a transaction
          tx = safe_find_or_create(txid: txid, user: user)

          # send the user notification, with record locking

          tx.with_lock do
            # populate the object from the JSON response
            tx.populate_from_daemon tx_account_data, tx_data
            tx.notify_user
            tx.save!
          end
        end
      end
    end

    # bitcoind's blocknotify is run as a thread, leading to concurrency issues
    # when finding/creating model records here
    def Transaction.safe_find_or_create(params = {})
      begin
        Transaction.find_or_create_by(txid: params[:txid], user: params[:user])
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.warn "unique constraint violation!"
        Transaction.find_by(txid: params[:txid], user: params[:user])
      end
    end

    def populate_from_daemon(raw_data = nil, raw_header_data = nil)
      # if we weren't already given raw data from a JSON call, fetch it
      unless raw_data
        rpc = RPC.new
        raw_header_data = rpc.gettransaction txid

        raw_data = raw_header_data.detect do |d|
          d.account == self.user.coin_account.name
        end
      end

      # massage JSON data into update parameters, update
      params = json_response_to_update raw_data, raw_header_data
      update params
    end

    # Notify owning user of this transaction, based on their preferences.
    # Optional block is called if a notification was sent.
    # TODO this should really be decoupled using a queue
    def notify_user
      return unless user.can_do_twilio?
      return if self.user_notified   # don't do this twice!

      case
      when user.notify_never?
        self.user_notified = true

      when user.notify_by_sms?
        client = Rails.application.twilio_client
        client.account.messages.create(:body => generate_sms_message,
                                       :to   => user.phone,
                                       :from => Rails.application.twilio_number)
        self.user_notified = true

      when user.notify_by_voice?
        # unimplemented as of yet
        #user_notified = false
      end

      block_given? and yield
    end

    def amount_as_text
      ApplicationController.helpers.amount_for_display(amount)
    end

    private

    # Can flatten a gettransactions response into an update hash.
    # listtransactions already returns a flat hash. In either case,
    # only valid params are selected
    def json_response_to_update(account_data, header_data = {})
      params = ActionController::Parameters.new(account_data)
      header_params = ActionController::Parameters.new(header_data)

      # start with the allowed fields from account information
      params = params.permit(ALLOWED_FIELDS)
      
      # augment from header information, if available
      header_params = header_params.permit(ALLOWED_FIELDS_HEADER)
      ALLOWED_FIELDS_HEADER.each do |f|
        if not params.has_key?(f) and header_params.has_key?(f)
          params[f] = header_params[f]
        end
      end

      # also convert fields from unix epoch seconds
      [:blocktime, :time, :timereceived].each do |f|
        params[f] = Time.at(params[f]) if params[f]
      end

      return params
    end

    def generate_sms_message
      msg = "Transaction for #{amount_as_text} " +
        "in category '#{category}' registered."
      if blockhash.blank?
        msg += " (unconfirmed)"
      end

      return msg
    end

    def set_defaults
      self.user_notified = false
    end
  end
end

module Coin
  # An ActiveRecord class to represent a Bitcoin transaction. The primary key
  # for each record is the transaction id and a user reference, so one
  # transaction between two application users will be represented with two rows.
  # These objects are persisted only to reliably send a single notification to
  # users for new transactions. Actual transaction details (amounts,
  # confirmations etc.) are sourced through the bitcoin RPC interface.
  class Transaction < ActiveRecord::Base
    # Fields that are mapped from the 'details' section of a JSON-RPC result
    # into object attributes
    ALLOWED_FIELDS = [:address, :category, :amount, :fee,
                      :confirmations, :blockhash, :blocktime,
                      :time, :timereceived, :comment, :confirmations]

    # Fields that are mapped from the header section of a JSON-RPC result into
    # object attributes
    ALLOWED_FIELDS_HEADER = ALLOWED_FIELDS.reject do |f|
      [:address, :category, :amount, :fee].include? f
    end

    ############################################################################
    ### ActiveRecord configurations, validations and call-backs
    belongs_to :user

    after_create do             # uses delayed_job to queue notifications
      self.delay.notify_user
    end
    ############################################################################

    # non-persisted attributes
    attr_accessor :category, :amount, :fee, :blockhash, :comment, :address,
    :confirmations, :blocktime, :time, :timereceived, :counterpart

    # Class method, called via bin/rails runner whenever bitcoind is notified of
    # a new transaction. This functionality must be configured via the
    # +walletnotify+ option to bitcoind.
    def Transaction.txnotify(txid)
      rpc = RPC.new
      tx_data = rpc.gettransaction txid

      # the details section lists transaction specifics for each affected user
      tx_data['details'].each do |tx_account_data|
        account_name = tx_account_data['account']

        # find the user by the account name
        user = account_name.blank? ? nil :
          User.find_by(username: account_name)

        if user
          # The bitcoind daemon spawns one notification process per user, and
          # unique constraint violations are pretty much guaranteed. If another
          # process has already created the record, it's been queued for
          # notification, so this process can end.
          begin
            Transaction.find_or_create_by(txid: txid, user: user)
            Rails.logger.debug "PID #{Process.pid} created TX record #{self}."

          rescue ActiveRecord::RecordNotUnique
            Rails.logger.warn "PID #{Process.pid} found #{self} prev. created."

          end
        end
      end
    end

    # Method to set the non-persisted attributes of this transaction by
    # querying the Bitcoin RPC daemon. +raw_data+ should be taken from the
    # _details_ section of the JSON response, +raw_header_data+ from the
    # response itself. If +raw_data+ is +nil+, a new RPC query is issued.
    def load_rpc_data!
      rpc = RPC.new
      header = rpc.gettransaction txid
      detail = header['details'].detect do |d|
        d['account'] == self.user.coin_account.name
      end
      
      apply_rpc_gettx_data! header, detail
    end

    def apply_rpc_listtx_data!(data)
      apply_setters! safe_rpc_params(data)
      return self
    end

    def apply_rpc_gettx_data!(header, detail)
      # massage JSON data into update parameters, and update ourselves
      apply_setters! safe_rpc_params(detail, header)

      # if we have a send/receive transaction, save the counterpart information
      if header['details'] and header['details'].length == 2
        sender = header['details'].detect {|d| d['category'] == 'send' }
        receiver = header['details'].detect {|d| d['category'] == 'receive' }
        
        self.counterpart = ((category == 'send' and receiver) or
                            (category == 'receive' and sender))
      end

      return self
    end

    # Notify owning user of this transaction, based on their preferences.
    def notify_user
      return unless user.can_do_twilio? # user has no phone number

      case
      when user.notify_by_sms?
        notification = Coin::Notification.new(tx: self, method: :sms)
      when user.notify_by_voice?
        notification = Coin::Notification.new(tx: self, method: :voice)
      end

      notification.run
    end

    def to_s
      "Tx %s [user %s]" % [self.txid, self.user]
    end

    private

    def safe_rpc_params(account_data, header_data = {})
      account_params, header_params = Hash.new, Hash.new

      # map only allowed object attributes from the RPC response.
      # the account-level fields take precedence.
      [
       [ALLOWED_FIELDS, account_data, account_params],
       [ALLOWED_FIELDS_HEADER, header_data, header_params]
      ].each do |level|
        keys, data, target = *level
        if data
          keys.zip(keys.map {|k| data[k.to_s] })
            .reject {|pair| pair[1].nil? }
            .each {|pair| target[pair[0]] = pair[1] }
        end
        
      end

      combined_params = header_params.merge(account_params)
      # also convert fields from unix epoch seconds
      # TODO keep functions in top-level array as well
      [:blocktime, :time, :timereceived].each do |f|
        combined_params[f] = Time.at(combined_params[f]) if combined_params[f]
      end

      return combined_params
    end

    # Take a hash of attribute names and calls the setter methods with the
    # corresponding values.
    def apply_setters!(updates)
      updates.each do |field, value|
        setter = (field.to_s + "=").to_sym
        self.send setter, value
      end
    end

  end
end

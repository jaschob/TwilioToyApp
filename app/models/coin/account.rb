# CoinAccount is a non-persisted object to represent a user's bitcoind account.
# Most methods are relayed to bitcoind via JSON-RPC.

module Coin
  class Account
    DEFAULT_RECENT_TRANSACTIONS = 7

    @@core_account = nil

    attr_reader :name

    def initialize(name)
      @name = name
    end

    # Returns the core account, which isn't assigned to any particular user.
    def Account.core
      @@core_account if @@core_account
      @@core_account = Account.new("")
      # bitcoind uses an empty string for the default account name

      block_given? and yield @@core_account or @@core_account
    end

    # Returns a hash listing the last activity
    def Account.last_activity
      rpc = RPC.new
      tx = rpc.listtransactions.last
      tx and tx['time'] and Time.at(tx['time'])
    end

    # Find the hash of the latest (longest) block in the blockchain
    def Account.best_block
      rpc = RPC.new
      rpc.getbestblockhash
    end

    # Returns a hash mapping each account name to its current balance.
    def Account.all_balances
      rpc = RPC.new
      rpc.listaccounts
    end

    # Returns the account's current balance. If a lot of balances are being
    # displayed, the caller can cut down on the number of RPC calls by fetching
    # all balances once, with Account.all_balances, and passing that information
    # as a parameter here.
    def balance(known_balances = {})
      known_balances.has_key?(name) && known_balances[name] ||
        rpc.getbalance(name)
    end

    # retrieves recent transactions from the bitcoind client
    def recent_tx(opts = {})
      from = opts.has_key?(:from) ? opts[:from] : 0
      count = opts.has_key?(:count) ? opts[:count] : DEFAULT_RECENT_TRANSACTIONS
      user = User.find_by(username: name)

      # make RPC calls to list transactions. some transactions are internal,
      # which we need to filter out
      raw_tx_list = []

      # a little ugly, but we have to page through results until we find enough
      # ones that are applicable to the target user
      begin
        batch = rpc.listtransactions(name, count, from)
        from += count

        raw_tx_list.push(*batch.select{ |i| i.has_key? 'txid' })        
      end while raw_tx_list.length < count and batch.length > 0

      # trim the list down to the required size
      raw_tx_list = raw_tx_list.first(count)
      
      # transform the raw data into transaction objects
      raw_tx_list.collect do |tx_data|
        # note: .new means unpersisted
        Transaction.new(txid: tx_data['txid'],
                        user: user).apply_rpc_listtx_data! tx_data
      end
    end

    # returns the default bitcoin address for the account
    def default_address
      rpc.getaccountaddress name
    end

    # moves the specified amount of BTC to another user's account. Note that this
    # is not a transaction that is broadcast to the net; it's internal only.
    # amount: a CoinDecimal, must be positive
    # to: either a user or an account name
    def move(amount, target)
      if amount.sign < 0
        raise ArgumentError, "Can't move negative amounts!"
      end

      current_balance = balance
      target_account_name = find_account_name target

      case
      when target_account_name == name
        raise ArgumentError, "Can't move amount to own account!"
      when current_balance < amount
        raise ArgumentError, "Moving #{amount} would overdraw account!"
      end

      rpc.move name, target_account_name, amount
    end

    def txsend(amount, recipient, comment = "")
      recipient_address = find_account_address recipient
      unless recipient_address
        raise ArgumentError "Unknown recipient for send!" 
      end

      rpc.sendfrom name, recipient_address, amount, 1, comment
      # that "1" means that the sender must have at least one confirmation
      # before funds can be spent
    end

    private

    def rpc
      RPC.new
    end

    private

    def find_account_name(obj)
      if obj.respond_to?(:coin_account) &&
          obj.coin_account.respond_to?(:name)
        obj.coin_account.name
      else
        obj.to_s
      end
    end

    def find_account_address(obj)
      if obj.respond_to?(:coin_account) &&
          obj.coin_account.respond_to?(:default_address)
        obj.coin_account.default_address
      else
        obj.to_s
      end
    end
  end
end

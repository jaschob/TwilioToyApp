require 'net/http'
require 'uri'
require 'json'
require 'bigdecimal'

class BigDecimal
  COIN_PRECISION = 8

  # Adding to_json allows the JSON module to correctly json-ify a BigDecimal.
  # Otherwise, the object is converted to a string
  def to_json(*)
    round(COIN_PRECISION).to_s("F")
  end
end


module Coin
  # Class to talk to bitcoind via JSON-RPC. Code lifted pretty much
  # straight from
  # https://en.bitcoin.it/wiki/API_reference_%28JSON-RPC%29#Ruby
  class RPC
    def initialize
      @app = Rails.application
      @logger = Rails.logger
      @uri = URI.parse(@app.coin_rpc_url)
    end
    
    def method_missing(name, *args)
      post_body = {
        'method' => name,
        'params' => args,
        'id'     => 'jsonrpc' }

      req = JSON.generate post_body
      @logger.debug "JSON-RPC call: #{req}"

      begin
        resp = JSON.parse http_post_request(req)
      rescue Errno::ECONNREFUSED # common, bitcoind is down!
        raise RPCConnectionError, "Bitcoin client not reachable!"
      end
      # this would be a useful feature...
      #resp = JSON.parse http_post_request(req), {
      #  decimal_class: BigDecimal
      #}

      # ... but til then, convert to BigDecimals by hand
      resp = floats2decimals(resp)

      if resp['error']
        @logger.error "JSON-RPC error: #{req} --> #{resp}"
        raise RPCError, resp['error']
      else
        resp['result']
      end
    end

    # Bitcoin errors generally return a code, though not sure how that helps.
    class RPCError < RuntimeError
      def initialize(error_obj = nil)
        Rails.logger.debug error_obj.inspect
        @message = error_obj ? error_obj['message'] : "Unspecified error"
        @code = error_obj ? error_obj['code'] : nil
      end

      def message
        @code.nil? ? @message : "#{@message} (code #{@code})"
      end
    end

    class RPCConnectionError < RuntimeError
    end

    # Ugly helper here to turn Floats returned by the JSON parser into
    # BigDecimals, which are safer. https://github.com/flori/json/issues/219.
    def floats2decimals(raw)
      processed = Hash.new
      raw.collect do |key, value|
        if value.class == Float # turn the Floats into BigDecimals
          processed[key] = BigDecimal.new(value, BigDecimal::COIN_PRECISION)

        # looks like a Hash
        elsif [:keys, :values, :each].all? {|m| value.respond_to? m}
          processed[key] = self.floats2decimals(value)

        # looks like an Array/Enumerable
        elsif [:each, :collect].all? {|m| value.respond_to? m}
          processed[key] = value.collect {|i| self.floats2decimals(i)}

        # something else: leave unchanged
        else
          processed[key] = value
        end
      end

      return processed
    end

    private

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    end
  end
end

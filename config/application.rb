require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TwilioCoin
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # attributes to configure talking to the (bit|alt|doge|...)coind
    # process via RPC JSON. These need to be defined for each
    # environment.
    #attr_accessor :coin_rpc_ssl, :coin_rpc_user, :coin_rpc_pass,
    #:coin_rpc_site

    def coin_rpc_url
      sprintf "%s://%s:%s@%s",
        (APP_CONFIG['coin_rpc_ssl'] ? "https" : "http"),
        *%w( user pass site ).map{|k| APP_CONFIG["coin_rpc_#{k}"]}
    end

    def new_user_donation_amount
      BigDecimal.new(APP_CONFIG['new_user_donation_amount'])
    end

    # Twilio functionality
    def twilio_client
      Twilio::REST::Client.new APP_CONFIG['twilio_account_sid'],
                               APP_CONFIG['twilio_auth_token']
    end

    def twilio_auth_token
      APP_CONFIG['twilio_auth_token']
    end

    def enforce_twilio_auth?
      APP_CONFIG['twilio_enforce_auth']
    end

    def twilio_number
      return APP_CONFIG['twilio_number']
    end
  end
end

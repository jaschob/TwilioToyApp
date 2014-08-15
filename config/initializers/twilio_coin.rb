# Initializes the application by reading config/config.yml for
# application parameters, most importantly the RPC connection info.
module TwilioCoin
  class Application < Rails::Application
    config.before_initialize do
      APP_CONFIG = YAML.load_file(Rails.root.join(
        'config/config.yml'))[Rails.env]
    end
  end
end

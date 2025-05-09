# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Application configuration for product management microservice API
module CommercecoreProductManagementService
  # application
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.generators do |generate|
      generate.orm :active_record, primary_key_type: :uuid
    end

    config.cache_store = :redis_cache_store, {
      url: ENV["REDIS_URL"],
      expires_in: 60.days,
      reconnect_attempts: 3
    }

    config.action_controller.raise_on_missing_callback_actions = false

    config.autoload_paths += %W[#{config.root}/app/validators]

    config.action_dispatch.rack_cache = true
    config.active_job.queue_adapter = :sidekiq

    # This also configures session_options for use below
    config.session_store :cookie_store, key: "_pms_sidekiq_session"

    # Required for all session management (regardless of session_store)
    config.middleware.use ActionDispatch::Cookies

    config.middleware.use config.session_store, config.session_options

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*",
                 headers: :any,
                 methods: %i[get post put patch delete options head]
      end
    end

    config.active_support.to_time_preserves_timezone = :zone
  end
end

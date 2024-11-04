# frozen_string_literal: true

SIDEKIQ_REDIS_CONFIGURATION = {
  url: ENV.fetch(ENV.fetch("REDIS_PROVIDER", "MESSAGE_BROKER_URL"), nil),
  network_timeout: 5, pool_timeout: 5,
  id: "PMS-API-Sidekiq-PID-#{::Process.pid}",
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}.freeze

Sidekiq.configure_server do |config|
  config.redis = SIDEKIQ_REDIS_CONFIGURATION

  config.queues = [
    [ "high_priority", ENV.fetch("HIGH_PRIORITY", 10).to_i ],
    [ "default", ENV.fetch("DEFAULT_PRIORITY", 5).to_i ],
    [ "low_priority", ENV.fetch("LOW_PRIORITY", 1).to_i ]
  ]

  config.concurrency = ENV.fetch("SIDEKIQ_CONCURRENCY", 10).to_i
end

Sidekiq.configure_client do |config|
  config.redis = SIDEKIQ_REDIS_CONFIGURATION
end

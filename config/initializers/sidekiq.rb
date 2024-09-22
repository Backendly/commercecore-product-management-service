# frozen_string_literal: true

Rails.logger.info 'Initializing Sidekiq'

Sidekiq.configure_server do |config|
  Rails.logger.info 'Configuring Sidekiq server'
  config.redis = { url: ENV['REDIS_URL'] }
  Rails.logger.info 'Sidekiq server configured'
end

Sidekiq.configure_client do |config|
  Rails.logger.info 'Configuring Sidekiq client'
  config.redis = { url: ENV['REDIS_URL'] }
  Rails.logger.info 'Sidekiq client configured'
end

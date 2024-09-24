# frozen_string_literal: true

# Base application job
class ApplicationJob < ActiveJob::Base
  # Set the redis client for the message broker redis server
  def message_broker
    Redis.new(url: ENV['MESSAGE_BROKER_URL'])
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer
  # available discard_on ActiveJob::DeserializationError
end

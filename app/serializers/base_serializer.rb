# frozen_string_literal: true

# Base serializer for all serializers in the application.
class BaseSerializer
  include JSONAPI::Serializer

  cache_options store: Rails.cache, namespace: 'json-serializer',
                expires_in: 1.day
end

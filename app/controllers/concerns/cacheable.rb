# frozen_string_literal: true

# Implements caching for controllers
module Cacheable
  extend ActiveSupport::Concern

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    after_action :invalidate_cache, except: %i[index show]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  def base_key
    "#{self.class.name.underscore}_dev_id_#{developer_id}"
  end

  # rubocop:disable Metrics/ParameterLists

  # Caches a collection of resources with a generated cache key.
  def cache_collection(
    collection, base_key, page:, page_size:, filters: {},
    expires_in: 1.day
  )
    cache_key = generate_list_cache_key(
      base_key:, page:, page_size:, filters:
    )

    updated_at_timestamp = collection.maximum(:updated_at).to_i

    cache_key = "#{cache_key}_#{updated_at_timestamp}"

    Rails.cache.fetch(cache_key, expires_in:) do
      yield(collection)
    end
  end

  # rubocop:enable Metrics/ParameterLists

  # Caches a single resource with a generated cache key.
  def cache_resource(cache_key, expires_in: 1.day, &block)
    Rails.cache.fetch(cache_key, expires_in:, &block)
  end

  # Invalidates the cache for both the resource and related lists.
  def invalidate_cache
    invalidate_list_cache(base_key:) if respond_to?(:invalidate_list_cache)
    return unless respond_to?(:invalidate_single_resource_cache)

    invalidate_single_resource_cache(current_cache_key)
  end

  # Generates a cache key for paginated lists based on filters.
  def generate_list_cache_key(base_key:, page:, page_size:, filters: {})
    key_parts = [ "#{base_key}_page_#{page}_size_#{page_size}" ]
    filters.each do |filter_key, filter_value|
      key_parts << "#{filter_key}_#{filter_value}" if filter_value.present?
    end
    key_parts.join("_")
  end

  # Invalidates all caches for paginated lists matching the developer ID.
  def invalidate_list_cache(base_key:)
    Rails.cache.delete_matched("#{base_key}*")
  end

  # Invalidates a specific resource's cache.
  def invalidate_single_resource_cache(cache_key)
    Rails.cache.delete(cache_key)
  end

  # Returns the current cache key based on the controller's context.
  def current_cache_key
    "#{base_key}_#{params[:id]}"
  end
end

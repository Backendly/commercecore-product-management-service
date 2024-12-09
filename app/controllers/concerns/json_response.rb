# frozen_string_literal: true

# JsonResponse provides a standardized way to render JSON responses in
# the API. It handles both paginated and single resource responses,
# merging common meta information.
module JsonResponse
  extend ActiveSupport::Concern
  include PaginationHelper

  # Renders the appropriate JSON response based on whether the resource is
  # paginated.
  #
  # @param resource [Object] The resource to render, can be a collection or
  #   a single object.
  # @param message [String] A custom message to include in the response
  #   metadata (default: 'Request successful').
  # @param extra_meta [Hash] Additional metadata to include in the response
  #   (default: {}).
  def json_response(
    resource, serializer:, message: "Request successful",
    extra_meta: {}, status: nil
  )
    code = status_code(status)
    metadata = {
      status_code: code,
      success: code < 400
    }.merge(extra_meta)

    if paginated?(resource)
      render_paginated(resource, message:, extra_meta: metadata, serializer:)
    else
      render_single(resource, message:, extra_meta: metadata, serializer:)
    end
  end

  private

    # Checks if the resource is paginated.
    #
    # @param resource [Object] The resource to check.
    # @return [Boolean] Returns true if the resource is paginated, false
    #   otherwise.
    def paginated?(resource)
      resource.respond_to?(:current_page) && resource.respond_to?(:total_pages)
    end

    # Renders a paginated JSON response.
    #
    # @param resource [Object] The paginated resource to render.
    # @param message [String] A custom message to include in the response
    #   metadata.
    # @param extra_meta [Hash] Additional metadata to include in the response.
    # @return [Hash] The complete JSON response with data, meta, and links.
    def render_paginated(resource, message:, extra_meta:, serializer:)
      # Use the paginate method from PaginationHelper
      pagination_data = paginate(resource, message:)

      # Merge the extra metadata into the pagination meta
      meta = pagination_data[:meta].merge(extra_meta)

      # Render the response
      serializer.new(resource).serializable_hash.merge(
        meta:, links: pagination_data[:links]
      )
    end

    # Renders a single JSON response.
    #
    # @param resource [Object] The single resource to render.
    # @param message [String] A custom message to include in the response
    #   metadata.
    # @param extra_meta [Hash] Additional metadata to include in the response.
    # @return [Hash] The complete JSON response with data and meta.
    def render_single(resource, message:, extra_meta:, serializer:)
      meta = { message: }.merge(extra_meta)

      serializer.new(resource).serializable_hash.merge(meta:)
    end

    def status_code(status)
      code = Rack::Utils.status_code(status)
      return code unless code.zero?

      request.method == "POST" ? 201 : 200
    end
end

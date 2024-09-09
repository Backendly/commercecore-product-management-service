# frozen_string_literal: true

# Helper for API response pagination
module PaginationHelper
  # rubocop:disable Metrics/MethodLength

  def paginate(resource, message: 'Records retrieved successfully')
    page = resource.current_page
    total_pages = resource.total_pages
    page_size = resource.limit_value

    links = {
      first: url_for(page: 1, page_size:),
      last: url_for(page: total_pages, page_size:),
      prev: (url_for(page: page - 1, page_size:) if page > 1),
      next: (url_for(page: page + 1, page_size:) if page < total_pages)
    }

    {
      meta: {
        total_count: resource.total_count,
        current_count: resource.count,
        message:
      },
      links:
    }
  end
end

# rubocop:enable Metrics/MethodLength

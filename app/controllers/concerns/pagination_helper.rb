# frozen_string_literal: true

# Helper for API response pagination
module PaginationHelper
  extend ActiveSupport::Concern

  included do
    class_attribute :max_pagination_size
    self.max_pagination_size = 100
  end

  # Determines the page size for pagination, ensuring it does not exceed
  # the maximum limit
  def page_size
    [
      params.fetch(:page_size, self.class.max_pagination_size).to_i,
      self.class.max_pagination_size
    ].min
  end

  def paginate(resource, message: "Records retrieved successfully")
    page = resource.current_page
    total_pages = [ resource.total_pages, 1 ].max
    page_size = resource.limit_value

    {
      meta: {
        total_count: resource.total_count,
        current_count: resource.count, message:
      },
      links: create_pagination_links(page, total_pages, page_size)
    }
  end

  private

    def create_pagination_links(page, total_pages, page_size)
      {
        first: url_for(page: 1, page_size:),
        last: url_for(page: total_pages, page_size:),
        prev: (url_for(page: page - 1, page_size:) if page > 1),
        next: (url_for(page: page + 1, page_size:) if page < total_pages)
      }
    end
end

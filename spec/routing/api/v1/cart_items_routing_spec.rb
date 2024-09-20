# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::CartItemsController, type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: 'api/v1/cart/items').to route_to('api/v1/cart_items#create')
    end

    it 'routes to #destroy' do
      expect(delete: 'api/v1/cart/items/1').to route_to(
        'api/v1/cart_items#destroy', id: '1'
      )
    end

    it 'routes to #show' do
      expect(get: 'api/v1/cart/items/1').to route_to(
        'api/v1/cart_items#show', id: '1'
      )
    end

    it 'routes to #index' do
      expect(get: 'api/v1/cart/items').to route_to('api/v1/cart_items#index')
    end
  end
end

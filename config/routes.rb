# frozen_string_literal: true

require 'sidekiq/web'

# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end

  mount Sidekiq::Web => '/sidekiq'

  namespace :api do
    namespace :v1 do
      get '/', to: 'root#index'
      get 'status', to: 'status#show'

      resources :products, only: %i[index show create update destroy] do
        member do
          post :images, to: 'products#upload_images', as: :upload_images
          delete 'images/:image_id', to: 'products#delete_image',
                                     as: :delete_image
        end
      end

      resources :categories, only: %i[index show create update destroy]
      resource :cart, only: %i[show] do
        post :checkout, to: 'checkout#create', as: :checkout
        resources :items, controller: 'cart_items',
                          only: %i[create show destroy index]
      end

      resources :orders, only: %i[index show] do
        member do
          post :cancel
        end
        resources :items, controller: 'order_items', only: %i[index show]
      end
    end
  end

  resolve('Cart') { %i[api v1 cart] }

  root to: redirect('/api/v1')

  match '*unmatched', to: 'application#invalid_route', via: :all
end

# rubocop:enable Metrics/BlockLength

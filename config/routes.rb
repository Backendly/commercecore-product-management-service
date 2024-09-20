# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show create update destroy] do
        member do
          post :images, to: 'products#upload_images', as: :upload_images
          delete 'images/:image_id', to: 'products#delete_image',
                                     as: :delete_image
        end
      end
      resources :categories, only: %i[index show create update destroy]
      resource :cart, only: %i[show] do
        resources :items, controller: 'cart_items',
                          only: %i[create show destroy index]
      end
    end
  end

  resolve('Cart') { %i[api v1 cart] }

  # Define your application routes per the DSL in
  # https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no
  # exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the
  # app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  match '*unmatched', to: 'application#invalid_route', via: :all
end

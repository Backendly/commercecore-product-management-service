# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_contexts'

RSpec.describe "Api::V1::Products", type: :request do
  include_context 'common data'

  before do
    mock_authentication(controller_class: Api::V1::ProductsController)
  end

  let!(:valid_attributes) do
    {
      product_one: {
        name: 'Tea Maker',
        description: 'A device for heating food quickly and easily. ' \
          'It is a kitchen appliance',
        price: 100,
        stock_quantity: 10,
        currency: 'USD',
        available: true,
        category_id: first_dev_category_kitchen.id
      },

      product_two: {
        name: 'Another Kitchen Product',
        description: 'A device for cooling food quickly and easily. ' \
          'It is a kitchen appliance',
        price: 200,
        stock_quantity: 50,
        currency: 'USD',
        available: true
      }
    }
  end

  let!(:invalid_attributes) do
    {
      product_with_no_name: {
        description: 'A device for heating food quickly and easily. ' \
          'It is a kitchen appliance',
        price: 100,
        stock_quantity: 10
      },

      product_with_no_price: {
        name: 'Refrigerator',
        description: 'A device for cooling food quickly and easily. ' \
          'It is a kitchen appliance',
        stock_quantity: 50
      },
      product_with_non_numeric_price: {
        name: 'Refrigerator',
        description: 'A device for cooling food quickly and easily. ' \
          'It is a kitchen appliance',
        price: '100',
        stock_quantity: 50
      },
      product_with_no_app_id: {
        name: 'Refrigerator',
        description: 'A device for cooling food quickly and easily. ' \
          'It is a kitchen appliance',
        price: '100',
        stock_quantity: 50
      }
    }
  end

  # create 3 products for each developer
  before do
    Product.create!(
      name: 'Microwave',
      description: 'A device for heating food quickly and' \
        'easily. It is a kitchen appliance',
      price: 100,
      stock_quantity: 10,
      currency: 'USD',
      available: true,
      developer_id: developers.dig(:first, :id),
      category_id: first_dev_category_kitchen.id,
      app_id: users.dig(:one, :app_id),
      user_id: users.dig(:one, :id)
    )
    Product.create!(
      name: 'Refrigerator',
      description: 'A device for cooling food quickly' \
        'and easily. It is a kitchen appliance',
      price: 200,
      stock_quantity: 50,
      currency: 'USD',
      available: true,
      developer_id: developers.dig(:first, :id),
      user_id: users.dig(:two, :id),
      app_id: users.dig(:two, :app_id),
      category_id: first_dev_category_kitchen.id
    )
    Product.create!(
      name: 'Toaster',
      description: 'A device for toasting bread quickly and ' \
        'easily. It is a kitchen appliance',
      price: 300,
      stock_quantity: 20,
      currency: 'USD',
      available: true,
      developer_id: developers.dig(:first, :id),
      user_id: users.dig(:two, :id),
      category_id: first_dev_category_kitchen.id,
      app_id: users.dig(:two, :app_id)
    )
  end

  describe "GET /index" do
    context 'with invalid or no authentication details' do
      context 'without X-Developer-Token and X-User-Id in the headers' do
        it 'returns 401 when not provided' do
          get api_v1_products_url

          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns the response in a JSON format' do
          get api_v1_products_url

          expect(response.content_type).to include('application/json')
        end

        it 'contains a message and error stating the token is missing' do
          get api_v1_products_url

          expect(response_body.dig(:details, :message)).to \
            include('Please provide a valid developer token')
          expect(response_body.dig(:details, :error)).to \
            eq('Invalid developer token')
        end

        it 'has the expected response body format' do
          get api_v1_products_url

          expect(response_body.keys).to contain_exactly(
            :error, :meta, :details
          )
          expect(response_body[:error]).to be_a(String)

          expect(response_body[:meta]).to be_a(Hash)
          expect(response_body[:meta].keys).to contain_exactly(
            :request_path, :request_method, :status_code, :success
          )

          expect(response_body[:details]).to be_a(Hash)
          expect(response_body[:details].keys).to contain_exactly(
            :error, :message
          )
        end

        it 'has the correct error data in the response' do
          get api_v1_products_url

          expect(response_body[:error]).to eq('Authorization failed')

          # validate the contents of the meta body
          metadata = response_body[:meta]

          expect(metadata[:request_path]).to eq(api_v1_products_url)
          expect(metadata[:request_method]).to eq('GET')
          expect(metadata[:status_code]).to eq(401)
          expect(metadata[:success]).to be(false)

          # validate the details in the details body
          details = response_body[:details]

          expect(details[:error]).to eq('Invalid developer token')
          expect(details[:message]).to eq(
            'Please provide a valid developer token in the header. ' \
              'E.g., X-Developer-Token: <developer_token>'
          )
        end
      end

      context 'with a X-Developer-Token header but not X-User-Id header' do
        before do
          allow_any_instance_of(UserServiceClient).to \
            receive(:fetch_developer_id).and_return(
              developers.dig(:first, :id)
            )
        end

        it 'returns a 401' do
          get api_v1_products_url,
              headers: { 'X-Developer-Token': UUID7.generate }

          expect(response).to have_http_status(:unauthorized)
          expect(response_body.dig(:meta, :status_code)).to eq(401)
        end

        it 'returns an error message mentioning X-User-Id is missing' do
          get api_v1_products_url,
              headers: { 'X-Developer-Token': UUID7.generate }

          expect(response_body.dig(:details, :error)).to eq('Invalid user ID')
          expect(response_body.dig(:details, :message)).to eq(
            'Please provide a valid user ID. E.g., X-User-Id: <user_id>'
          )
        end
      end
    end

    context 'with valid authentication credentials' do
      let!(:expected_developer_id) { developers.dig(:first, :id) }

      before do
        mock_authentication(
          controller_class: Api::V1::ProductsController,
          developer_id: developers.dig(:first, :id),
          user_id: users.dig(:one, :id),
          app_id: users.dig(:one, :app_id)
        )

        Rails.cache.clear

        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(Product).to receive(:where).and_call_original
      end

      it "renders a successful response" do
        get api_v1_products_url, headers: valid_headers[:first_dev], as: :json

        expect(response).to be_successful
      end

      context 'without filters' do
        it 'returns all products' do
          get api_v1_products_url, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:success)
          expect(response_body[:data].size).to eq(3)
        end
      end

      context 'with name filter' do
        let!(:filtered_product) do
          FactoryBot.create(:product,
                            name: 'Filtered Product',
                            developer_id: developers.dig(:first, :id),
                            user_id: users.dig(:one, :id),
                            app_id: users.dig(:one, :app_id),
                            price: 100,
                            stock_quantity: 10,
                            description: 'A filtered case' * 10,
                            category_id: nil)
        end

        it 'returns filtered products by name' do
          get api_v1_products_url, headers: valid_headers[:first_dev],
                                   params: { name: 'Filtered Product' }

          expect(response).to have_http_status(:success)
          expect(response_body[:data].size).to eq(1)
          expect(response_body[:data].first.dig(:attributes, :name)).to \
            eq('Filtered Product')
        end
      end

      context 'with category filter' do
        it 'returns filtered products by category' do
          get api_v1_products_url,
              headers: valid_headers[:first_dev],
              params: { category_id: first_dev_category_kitchen.id }

          expect(response).to have_http_status(:success)
          expect(response_body[:data].size).to eq(3)

          # ensure all products returned are in the specified category
          response_body[:data].each do |product|
            expect(product.dig(:relationships, :category, :data, :id)).to \
              eq(first_dev_category_kitchen.id)
          end
        end
      end

      context 'with price range filter' do
        let!(:cheap_price) do
          FactoryBot.create(:product,
                            name: 'Cheap Product',
                            developer_id: developers.dig(:first, :id),
                            user_id: users.dig(:one, :id),
                            app_id: users.dig(:one, :app_id),
                            price: 5,
                            stock_quantity: 10,
                            description: 'A cheap product ' * 4,
                            category_id: first_dev_category_kitchen.id)
        end

        let!(:expensive_price) do
          FactoryBot.create(:product,
                            name: 'Expensive Product',
                            developer_id: developers.dig(:first, :id),
                            user_id: users.dig(:one, :id),
                            app_id: users.dig(:one, :app_id),
                            price: 15,
                            stock_quantity: 10,
                            description: 'An expensive product ' * 4,
                            category_id: first_dev_category_kitchen.id)
        end

        it 'returns products within the specified price range' do
          get api_v1_products_url, headers: valid_headers[:first_dev],
                                   params: { min_price: 5, max_price: 10 }

          expect(response).to have_http_status(:success)
          expect(response_body[:data].size).to eq(1)
          expect(response_body[:data].first.dig(:attributes, :name)).to \
            eq('Cheap Product')
          expect(response_body[:data].first.dig(
            :attributes, :price
          ).to_i).to eq(5)
        end
      end
    end

    describe 'caching' do
      before do
        mock_authentication(
          controller_class: Api::V1::ProductsController,
          developer_id: developers.dig(:first, :id),
          user_id: users.dig(:one, :id),
          app_id: users.dig(:one, :app_id)
        )

        Rails.cache.clear

        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(Product).to receive(:where).and_call_original
      end

      let(:base_key) do
        "api/v1/products_controller_dev_id_#{developers.dig(:first, :id)}"
      end
      let(:page) { 1 }
      let(:page_size) { 100 }
      let(:developer_id) { developers.dig(:first, :id) }
      let(:app_id) { developers.dig(:first, :app_id) }
      let(:updated_at_timestamp) do
        Product.where(developer_id:, app_id:).maximum(:updated_at).to_i
      end

      it 'caches the product response' do
        get api_v1_products_url, headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:ok)
        expect(Rails.cache).to have_received(:fetch)
          .with(
            "#{base_key}_page_#{page}_size_#{page_size}_" \
              "#{updated_at_timestamp}",
            expires_in: 2.hours
          )
      end

      it 'caches the product response with filters' do
        get api_v1_products_url, headers: valid_headers[:first_dev],
                                 params: { name: 'Microwave' }

        expect(response).to have_http_status(:ok)

        expect(Rails.cache).to have_received(:fetch)
          .with(
            "#{base_key}_page_#{page}_size_#{page_size}_name_Microwave_" \
              "#{updated_at_timestamp}",
            expires_in: 2.hours
          )
      end
    end
  end

  describe "GET /show" do
    before do
      mock_authentication(
        controller_class: Api::V1::ProductsController,
        developer_id: developers.dig(:first, :id),
        user_id: users.dig(:one, :id),
        app_id: users.dig(:one, :app_id)
      )
    end

    let!(:product) do
      Product.find_by(developer_id: developers.dig(:first, :id),
                      app_id: users.dig(:one, :app_id))
    end

    it "renders a successful response" do
      get api_v1_product_url(product), headers: valid_headers[:first_dev]

      expect(response).to have_http_status(:ok)
    end

    it 'returns the expected response body format' do
      get api_v1_product_url(product), headers: valid_headers[:first_dev]
      expect(response).to have_http_status(:ok)

      expect(response_body.keys).to contain_exactly(
        :data, :meta
      )
      expect(response_body[:data]).to be_a(Hash)
      expect(response_body[:data].keys).to contain_exactly(
        :id, :type, :attributes, :relationships
      )
    end

    it 'returns the expected product data' do
      get api_v1_product_url(product), headers: valid_headers[:first_dev]
      expect(response).to have_http_status(:ok)

      product_data = response_body[:data]
      product_attributes = product_data[:attributes]

      expect(product_data[:id]).to eq(product.id)
      expect(product_data[:type]).to eq('product')
      expect(product_attributes[:name]).to eq(product.name)
      expect(product_attributes[:description]).to eq(product.description)
      expect(product_attributes[:price].to_f).to eq(product.price.to_f)
      expect(product_attributes[:stock_quantity]).to eq(product.stock_quantity)
      expect(product_attributes[:currency]).to eq(product.currency)
      expect(product_attributes[:available]).to eq(product.available)
    end

    context 'errors' do
      it 'returns a 404 status code for non-existent products' do
        get api_v1_product_url(UUID7.generate),
            headers: valid_headers[:first_dev]

        expect(response).to have_http_status(404)
      end

      it 'returns the expected response body format for errors' do
        get api_v1_product_url(UUID7.generate),
            headers: valid_headers[:first_dev]

        expect(response_body.keys).to contain_exactly(
          :error, :meta, :details
        )
        expect(response_body[:error]).to be_a(String)

        expect(response_body[:meta]).to be_a(Hash)
        expect(response_body[:meta].keys).to contain_exactly(
          :request_path, :request_method, :status_code, :success
        )

        expect(response_body[:details]).to be_a(Hash)
        expect(response_body[:details].keys).to contain_exactly(:message)
      end
    end

    it 'returns a JSON response' do
      get api_v1_product_url(UUID7.generate),
          headers: valid_headers[:first_dev]
      expect(response.content_type).to include('application/json')
    end
  end

  describe "POST /create" do
    before do
      mock_authentication(
        controller_class: Api::V1::ProductsController,
        developer_id: developers.dig(:first, :id),
        user_id: users.dig(:one, :id),
        app_id: users.dig(:one, :app_id)
      )
    end

    context "with valid parameters" do
      it "creates a new Product" do
        expect do
          post api_v1_products_url,
               params: { product: valid_attributes[:product_one] },
               headers: valid_headers[:first_dev], as: :json
        end.to change(Product, :count).by(1)
      end

      it 'returns a 201 status code' do
        post api_v1_products_url,
             params: { product: valid_attributes[:product_one] },
             headers: valid_headers[:first_dev], as: :json

        expect(response).to have_http_status(:created)
      end

      it "renders a JSON response with the new product" do
        post api_v1_products_url,
             params: { product: valid_attributes[:product_one] },
             headers: valid_headers[:first_dev], as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
      end

      context "the category_id doesn't belong to the current developer" do
        it 'returns a 400: Category does not exist' do
          product = valid_attributes[:product_two].merge(
            category_id: second_dev_category_computers.id
          )

          post api_v1_products_url,
               params: { product: },
               headers: valid_headers[:first_dev], as: :json

          expect(response).to have_http_status(400)
        end

        it 'returns a JSON response with the error message' do
          product = valid_attributes[:product_two].merge(
            category_id: second_dev_category_computers.id
          )

          post api_v1_products_url,
               params: { product: },
               headers: valid_headers[:first_dev], as: :json

          expect(response.content_type).to include("application/json")
        end

        it 'has the expected error messages' do
          product = valid_attributes[:product_two].merge(
            category_id: second_dev_category_computers.id
          )

          post api_v1_products_url,
               params: { product: },
               headers: valid_headers[:first_dev], as: :json

          expect(response_body.dig(:details, :message)).to \
            include('Verify you have the category you specified')

          expect(response_body[:error]).to eq('Category not found')
        end
      end
    end

    context "with invalid parameters" do
      it "does not create a new Product" do
        expect do
          post api_v1_products_url,
               headers: valid_headers[:first_dev],
               params: { product: invalid_attributes }, as: :json
        end.not_to change(Product, :count)
      end

      it "renders a JSON response with errors for the new product" do
        post api_v1_products_url,
             params: { product: invalid_attributes },
             headers: valid_headers[:first_dev], as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.content_type).to include("application/json")
      end

      it 'returns a 422 when the product price is not provided' do
        post api_v1_products_url,
             params: { product: invalid_attributes[:product_with_no_price] },
             headers: valid_headers[:first_dev], as: :json

        expect(response).to have_http_status(422)
      end

      it 'returns a 422 when the price is a not a numeric value' do
        post api_v1_products_url,
             params: {
               product: invalid_attributes[:product_with_non_numeric_price]
             },
             headers: valid_headers[:first_dev], as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with invalid parameters" do
      it "returns a 422 status code for each invalid attribute set" do
        invalid_attributes.each do |key, value|
          post api_v1_products_url,
               params: { product: value },
               headers: valid_headers[:first_dev], as: :json

          expect(response).to have_http_status(422),
                              "Expected 422 for #{key} but got" \
                                " #{response.status}"
        end
      end
    end
  end

  describe "PATCH /update" do
    before do
      mock_authentication(
        controller_class: Api::V1::ProductsController,
        developer_id: developers.dig(:first, :id),
        user_id: users.dig(:one, :id),
        app_id: users.dig(:one, :app_id)
      )
    end

    context "with valid parameters" do
      let!(:product) { Product.first }
      let(:new_attributes) { { name: 'Updated Product name' } }

      it "updates the requested product" do
        patch api_v1_product_url(product),
              params: { product: new_attributes },
              headers: valid_headers[:first_dev], as: :json
        product.reload
        expect(product.name).to eq(new_attributes[:name])
      end

      it "renders a JSON response with the product" do
        patch api_v1_product_url(product),
              params: { product: new_attributes },
              headers: valid_headers[:first_dev], as: :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")
      end
    end
  end

  describe "DELETE /destroy" do
    before do
      mock_authentication(
        controller_class: Api::V1::ProductsController,
        developer_id: developers.dig(:first, :id),
        user_id: users.dig(:one, :id),
        app_id: users.dig(:one, :app_id)
      )
    end

    let(:product) { Product.first }

    it "destroys the requested product" do
      expect do
        delete api_v1_product_url(product),
               headers: valid_headers[:first_dev], as: :json
      end.to change(Product, :count).by(-1)
    end

    it 'returns a 204 status code' do
      delete api_v1_product_url(product),
             headers: valid_headers[:first_dev], as: :json

      expect(response).to have_http_status(:no_content)
    end

    it 'returns no content in the response body' do
      delete api_v1_product_url(product),
             headers: valid_headers[:first_dev], as: :json

      expect(response.body).to be_empty
    end
  end

  describe 'Product Images' do
    before do
      mock_authentication(
        controller_class: Api::V1::ProductsController,
        developer_id: developers.dig(:first, :id),
        user_id: users.dig(:one, :id),
        app_id: users.dig(:one, :app_id)
      )
    end

    let(:product) { Product.first }
    let(:image1) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/product_image_1.png")
      )
    end
    let(:image2) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/product_image_2.jpg")
      )
    end
    let(:image3) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/product_image_3.jpg")
      )
    end
    let(:large_file) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/large_image.jpg")
      )
    end
    let(:invalid_image) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/just_text.txt")
      )
    end

    context "when adding images to products" do
      it 'attaches an image to a product' do
        product = Product.first

        post upload_images_api_v1_product_url(product),
             params: { images: [image1, image2, image3] },
             headers: valid_headers[:first_dev]

        expect(product.images.attached?).to be_truthy
        expect(product.images.count).to eq(3)
        expect(response).to have_http_status(:ok)
      end

      it 'returns a 404 status code for non-existent products' do
        post upload_images_api_v1_product_url(UUID7.generate),
             headers: valid_headers[:first_dev]

        expect(response).to have_http_status(404)
      end

      it 'returns the expected response body format for errors' do
        post upload_images_api_v1_product_url(UUID7.generate),
             headers: valid_headers[:first_dev]

        expect(response_body.keys).to contain_exactly(
          :error, :meta, :details
        )
        expect(response_body[:error]).to be_a(String)

        expect(response_body[:meta]).to be_a(Hash)
        expect(response_body[:meta].keys).to contain_exactly(
          :request_path, :request_method, :status_code, :success
        )

        expect(response_body[:details]).to be_a(Hash)
        expect(response_body[:details].keys).to contain_exactly(:message)

        # check the validity of the type of the error message
        expect(response_body[:error]).to eq('Product not found')
        expect(response_body[:details][:message]).to include(
          "Couldn't find Product with id"
        )
      end

      it 'fails for non-image files' do
        product = Product.first

        post upload_images_api_v1_product_url(product),
             params: { images: [invalid_image] },
             headers: valid_headers[:first_dev]

        expect(product.images.attached?).to be_falsey
        expect(product.images.count).to eq(0)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'fails for images that exceed the maximum size' do
        product = Product.first

        post upload_images_api_v1_product_url(product),
             params: { images: [large_file] },
             headers: valid_headers[:first_dev]

        expect(product.images.attached?).to be_falsey
        expect(product.images.count).to eq(0)
        expect(response).to have_http_status(:unprocessable_content)

        expect(response_body[:details].first).to include("must be less than")
      end
    end

    context "when deleting images from products" do
      it 'deletes an image from a product' do
        product.images.attach(image1)

        delete delete_image_api_v1_product_url(product, product.images.first),
               headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:success)
      end

      it 'returns a 404 status code for non-existent products' do
        delete delete_image_api_v1_product_url(UUID7.generate, UUID7.generate),
               headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:not_found)
      end

      it 'returns a 404 status code for non-existent images' do
        product = Product.first

        delete delete_image_api_v1_product_url(product, UUID7.generate),
               headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when listing products" do
      it 'returns a list of images for a product' do
        product.images.attach(image1, image2, image3)

        get api_v1_product_url(product),
            headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:success)
        expect(response_body.dig(:data, :attributes, :images).size).to eq(3)
      end

      it 'returns a 404 status code for non-existent products' do
        get api_v1_product_url(UUID7.generate),
            headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:not_found)
      end

      it 'returns an empty array for products with no images' do
        product = Product.last

        get api_v1_product_url(product),
            headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:success)
        expect(response_body.dig(:data, :attributes, :images)).to be_empty
      end
    end

    describe 'Deleting' do
      context 'when the image is not found' do
        it 'returns a 404 status code' do
          delete delete_image_api_v1_product_url(product, UUID7.generate),
                 headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end

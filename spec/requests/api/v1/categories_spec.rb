# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "/api/v1/categories", type: :request do
  let(:valid_attributes) do
    { name: 'Home Appliance',
      description: 'Everything home appliance goes here' }
  end

  let(:first_developer_token) { UUID7.generate }
  let(:second_developer_token) { UUID7.generate }

  let(:invalid_attributes) do
    { name: '', description: '' } # no category name and description
  end

  # initial validation validation is done for the first developer token
  let!(:first_dev_headers) do
    {
      'Content-Type' => 'application/json',
      'X-Developer-Token' => first_developer_token
    }
  end

  let!(:second_dev_headers) do
    {
      'Content-Type' => 'application/json',
      'X-Developer-Token' => second_developer_token
    }
  end

  context 'with valid developer token' do
    before do
      # always return true for developer token validation
      allow_any_instance_of(Api::V1::CategoriesController).to \
        receive(:valid_developer_token?).and_return(true)
    end

    let!(:first_dev_category) do
      Category.create! valid_attributes.merge(
        developer_id: first_developer_token
      )
    end

    let!(:second_dev_category) do
      Category.create!(
        name: 'Computer Accessories',
        description: 'Contains products such as keyboards mice, etc.',
        developer_id: second_developer_token
      )
    end

    # ensure that there are two categories at the start of the test
    it 'starts with 2 categories in the database' do
      expect(Category.count).to eq(2)
    end

    describe "GET /index" do
      it "renders a successful response" do
        get api_v1_categories_url, headers: first_dev_headers
        expect(response).to be_successful
      end

      it "contains data object for actual response data" do
        get api_v1_categories_url, headers: first_dev_headers
        expect(response_body).to include(:data)
      end

      it 'contains RESTful meta information' do
        get api_v1_categories_url, headers: first_dev_headers
        expect(response).to have_http_status(:ok)

        expect(response_body).to have_key(:meta)
        meta = response_body[:meta]

        expect(meta).to include(:message, :total_count, :current_count)
      end

      describe 'Pagination' do
        it 'contains pagination links' do
          get api_v1_categories_url, headers: first_dev_headers

          expect(response).to have_http_status(:ok)
          expect(response_body).to have_key(:links)

          pagination_links = response_body[:links]

          expect(pagination_links).to include(:first, :last, :prev, :next)

          expect(pagination_links[:prev]).to eq(nil)
          expect(pagination_links[:next]).to eq(nil)

          expect(pagination_links[:first]).to eq(
            "#{request.url}?page=1&page_size=100"
          )
          expect(pagination_links[:last]).to eq(
            "#{request.url}?page=1&page_size=100"
          )
        end

        it 'responds to page_size query parameter' do
          get api_v1_categories_url, params: { page_size: 1 },
                                     headers: first_dev_headers

          expect(response).to have_http_status(:ok)

          # the first developer has only one category created so far
          expect(response_body.dig(:meta, :current_count)).to eq(1)
          expect(response_body.dig(:meta, :total_count)).to eq(1)
          expect(response_body[:data].size).to eq(1)
        end

        it 'limits the page size to 100' do
          get api_v1_categories_url, params: { page_size: 101 },
                                     headers: first_dev_headers

          expect(response).to have_http_status(:ok)
          expect(response_body[:meta][:current_count]).to be <= 100
          expect(response_body.dig(:links, :first)).to eq(
            "#{request.base_url}/api/v1/categories?page=1&page_size=100"
          )
        end
      end

      describe 'Response data body' do
        let!(:categories) { [Category.first, Category.last] }

        it 'has all the required and follows the JSON:API standard' do
          get api_v1_categories_url, headers: first_dev_headers

          expect(response).to have_http_status(:ok)
          expect(response_body[:data]).to be_an(Array)

          response_data = response_body[:data]

          response_data.each_with_index do |data, index|
            expect(data).to include(:id, :type, :attributes)
            expect(data[:attributes]).to be_a(Hash)
            expect(data[:attributes]).to include(
              :name, :description,
              :developer_id, :created_at, :updated_at, :links
            )
            expect(data.dig(:attributes, :links)).to be_a(Hash)

            expect(data.dig(:attributes, :links)).to have_key(:self)
            expect(
              data.dig(:attributes, :links, :self)
            ).to eq(api_v1_category_url(categories[index]))
          end
        end

        it 'has the same data as the ones stored in the database' do
          get api_v1_categories_url, headers: first_dev_headers

          expect(response).to have_http_status(:ok)
          response_data = response_body[:data]

          response_data.each_with_index do |data, index|
            category = categories[index]

            expect(data[:id]).to eq(category.id)
            expect(data.dig(:attributes, :name)).to eq(category.name)
            expect(data.dig(:attributes,
                            :developer_id)).to eq(category.developer_id)
            expect(data.dig(:attributes,
                            :description)).to eq(category.description)
            expect(data.dig(:attributes,
                            :created_at)).to eq(category.created_at.iso8601(3))
            expect(data.dig(:attributes,
                            :updated_at)).to eq(category.updated_at.iso8601(3))
          end
        end

        it 'contains only the resources owned by the authenticated developer' do
          get api_v1_categories_url, headers: first_dev_headers

          expect(response).to have_http_status(:ok)
          response_data = response_body[:data]

          response_data.each do |data|
            expect(data.dig(:attributes, :developer_id)).to eq(
              first_dev_headers['X-Developer-Token']
            )
          end
        end
      end

      context 'with query parameters in the request path' do
        before do
          Category.create!(
            name: 'Body lotions', description: 'Skin care products',
            developer_id: first_developer_token
          )
        end

        context 'with filters based on the name' do
          it 'filters the categories based on the name' do
            get api_v1_categories_url,
                params: { name: 'Body lotions' },
                headers: first_dev_headers

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(1)

            response_data = response_body[:data]

            expect(response_data.first.dig(:attributes, :name)).to \
              eq('Body lotions')
          end

          it 'returns an empty array when no match is found' do
            get api_v1_categories_url,
                params: { name: 'Body lotions' },
                headers: second_dev_headers # second dev does not have this one

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(0)
          end

          it 'returns all categories when the filter is not found' do
            get api_v1_categories_url,
                params: { unknown: 'Body lotions' },
                headers: first_dev_headers

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(2)
          end
        end

        context "with filters based on the 'search' keyword" do
          it 'returns all categories with the searched keyword' do
            get api_v1_categories_url,
                params: { search: 'home' },
                headers: first_dev_headers

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(1)

            response_data = response_body[:data]

            expect(response_data.first.dig(:attributes, :name)).to \
              eq('Home Appliance')
          end
        end
      end
    end

    describe "GET /show" do
      context "with the first developer's token" do
        it "renders a successful response" do
          get api_v1_category_url(first_dev_category),
              headers: first_dev_headers
          expect(response).to be_successful
        end

        it "contains data object for actual response data" do
          get api_v1_category_url(first_dev_category),
              headers: first_dev_headers
          expect(response_body).to include(:data)
        end

        it "contains the exact data for the category requested" do
          get api_v1_category_url(first_dev_category),
              headers: first_dev_headers

          expect(response).to have_http_status(:ok)
          expect(response_body[:data]).to include(:id, :type, :attributes)

          response_data = response_body[:data]

          expect(response_data.dig(:attributes, :name)).to eq(
            first_dev_category.name
          )
          expect(response_data.dig(:attributes, :description)).to eq(
            first_dev_category.description
          )
          expect(response_data.dig(:attributes, :developer_id)).to eq(
            first_dev_category.developer_id
          )
        end

        it "gets a 404 when the category is not found" do
          get api_v1_category_url(UUID7.generate), headers: first_dev_headers
          expect(response).to have_http_status(:not_found)
        end

        it "rejects requests from developers who do not own the category" do
          get api_v1_category_url(first_dev_category),
              headers: second_dev_headers

          expect(response).to have_http_status(:not_found)
        end
      end

      context "with the second developer's token" do
        it "renders a successful response" do
          get api_v1_category_url(second_dev_category),
              headers: second_dev_headers
          expect(response).to be_successful
        end

        it "contains data object for actual response data" do
          get api_v1_category_url(second_dev_category),
              headers: second_dev_headers
          expect(response_body).to include(:data)
        end

        it "contains the exact data for the category requested" do
          get api_v1_category_url(second_dev_category),
              headers: second_dev_headers

          expect(response).to have_http_status(:ok)
          expect(response_body[:data]).to include(:id, :type, :attributes)

          response_data = response_body[:data]

          expect(response_data.dig(:attributes, :name)).to eq(
            second_dev_category.name
          )
          expect(response_data.dig(:attributes, :description)).to eq(
            second_dev_category.description
          )
          expect(response_data.dig(:attributes, :developer_id)).to eq(
            second_dev_category.developer_id
          )
        end

        it "gets a 404 when the category is not found" do
          get api_v1_category_url(UUID7.generate), headers: second_dev_headers
          expect(response).to have_http_status(:not_found)
        end

        it "rejects requests from developers who do not own the category" do
          get api_v1_category_url(second_dev_category),
              headers: first_dev_headers

          expect(response).to have_http_status(:not_found)
        end
      end

      describe "POST /create" do
        context "with valid parameters" do
          it "creates a new Category" do
            expect do
              post api_v1_categories_url,
                   params: {
                     category: {
                       name: 'Body Lotions',
                       description: 'This category is for skin care products'
                     }
                   },
                   headers: first_dev_headers, as: :json
            end.to change(Category, :count).by(1)

            expect(response).to have_http_status(:created)
            expect(response.content_type).to include('application/json')

            expect(response_body[:data]).to include(:id, :type, :attributes)
            expect(response_body[:data][:attributes]).to include(
              :name, :description, :developer_id, :created_at,
              :updated_at, :links
            )

            # now let's validate the response data
            response_data = response_body[:data]

            expect(response_data.dig(:attributes,
                                     :name)).to eq('Body Lotions')
          end

          it 'sends a 409 error when duplicates are attempted' do
            expect do
              post api_v1_categories_url,
                   params: {
                     category: {
                       name: first_dev_category.name,
                       description: first_dev_category.description
                     }
                   },
                   headers: first_dev_headers, as: :json
            end.not_to change(Category, :count)

            expect(response).to have_http_status(:conflict)

            expect(response_body[:error]).to eq("Duplicate object found")
          end

          it "renders a JSON response with the newly created category" do
            post api_v1_categories_url,
                 params: {
                   category: {
                     name: 'Body Lotions',
                     description: 'This category is for skin care products'
                   }
                 },
                 headers: first_dev_headers, as: :json

            expect(response).to have_http_status(:created)
            expect(response.content_type).to include("application/json")
          end
        end

        context "with invalid parameters" do
          it "does not create a new Category" do
            expect do
              post api_v1_categories_url,
                   headers: first_dev_headers,
                   params: { api_v1_category: invalid_attributes }, as: :json
            end.to change(Category, :count).by(0)
          end

          it "renders a JSON response with errors for the new category" do
            post api_v1_categories_url,
                 params: { category: invalid_attributes },
                 headers: first_dev_headers, as: :json
            expect(response).to have_http_status(:unprocessable_content)
            expect(response.content_type).to include("application/json")
          end
        end
      end

      describe "PATCH /update" do
        context "with valid parameters" do
          let(:new_attributes) do
            {
              description: 'This category holds all home appliances products',
              name: 'UK Home-used Appliances'
            }
          end

          it "updates the requested category" do
            patch api_v1_category_url(first_dev_category),
                  params: { category: new_attributes },
                  headers: first_dev_headers, as: :json

            first_dev_category.reload
            expect(response).to have_http_status(:ok)

            expect(first_dev_category.description).to eq(
              new_attributes[:description]
            )
            expect(first_dev_category.name).to eq(new_attributes[:name])
          end

          it "renders a JSON response with the category" do
            patch api_v1_category_url(first_dev_category),
                  params: { category: new_attributes },
                  headers: first_dev_headers, as: :json

            expect(response).to have_http_status(:ok)
            expect(response.content_type).to include("application/json")
          end

          it "rejects updates from developers who do not own the category" do
            patch api_v1_category_url(first_dev_category),
                  params: { category: new_attributes },
                  headers: second_dev_headers, as: :json

            # for the sake of security, we will just tell them the item wasn't
            # found because they don't own it.
            expect(response).to have_http_status(:not_found)
          end
        end

        context "with invalid parameters" do
          it "renders a JSON response with errors for the category" do
            patch api_v1_category_url(first_dev_category),
                  params: { category: invalid_attributes },
                  headers: first_dev_headers, as: :json
            expect(response).to have_http_status(:unprocessable_content)

            expect(response.content_type).to include("application/json")
          end
        end
      end

      describe "DELETE /destroy" do
        it "destroys the requested category if it exists" do
          expect do
            delete api_v1_category_url(first_dev_category),
                   headers: first_dev_headers, as: :json
          end.to change(Category, :count).by(-1)

          expect(response).to have_http_status(:no_content)
        end

        it 'returns 404 when the requested category is not found' do
          expect do
            delete api_v1_category_url(UUID7.generate),
                   headers: first_dev_headers, as: :json
          end.not_to change(Category, :count)

          expect(response).to have_http_status(:not_found)
        end

        it 'returns an empty response body on success' do
          expect do
            delete api_v1_category_url(first_dev_category),
                   headers: first_dev_headers,
                   as: :json
          end.to change(Category, :count).by(-1)

          expect(response).to have_http_status(:no_content)
          expect(response.body.empty?).to be(true)
        end

        it "rejects deletions from developers who do not own the category" do
          delete api_v1_category_url(first_dev_category),
                 headers: second_dev_headers, as: :json

          # for the sake of security, we will just tell them the item wasn't
          # found because they don't own it.
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  context 'with an invalid or missing developer token' do
    before do
      # always return false for developer token validation
      allow_any_instance_of(Api::V1::CategoriesController).to \
        receive(:valid_developer_token?).and_return(false)
    end

    describe '/index' do
      it 'returns a 401 with no dev token' do
        get api_v1_categories_url

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 for invalid developer token' do
        get api_v1_categories_url,
            headers: { 'X-Developer-Token': UUID7.generate }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe '/create' do
      it 'returns a 401 when developer token is not provided' do
        post api_v1_categories_url, params: { category: valid_attributes }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 for invalid developer token' do
        post api_v1_categories_url,
             params: { category: valid_attributes },
             headers: { 'X-Developer-Token': UUID7.generate }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe '/show' do
      it 'returns a 401 with no dev token' do
        get api_v1_category_url(UUID7.generate)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 for invalid developer token' do
        get api_v1_category_url(UUID7.generate),
            headers: { 'X-Developer-Token': UUID7.generate }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe '/update (PUT | PATCH)' do
      it 'returns a 401 when developer token is not provided' do
        put api_v1_category_url(UUID7.generate),
            params: { category: valid_attributes }

        expect(response).to have_http_status(:unauthorized)

        patch api_v1_category_url(UUID7.generate),
              params: { category: valid_attributes }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 for invalid developer token' do
        put api_v1_categories_url,
            params: { category: valid_attributes },
            headers: { 'X-Developer-Token': UUID7.generate }

        expect(response).to have_http_status(:unauthorized)

        patch api_v1_categories_url,
              params: { category: valid_attributes },
              headers: { 'X-Developer-Token': UUID7.generate }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe '/destroy' do
      it 'returns a 401 with no dev token' do
        delete api_v1_category_url(UUID7.generate)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 for invalid developer token' do
        delete api_v1_category_url(UUID7.generate),
               headers: { 'X-Developer-Token': UUID7.generate }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

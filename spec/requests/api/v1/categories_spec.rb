# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_contexts'

RSpec.describe "/api/v1/categories", type: :request do
  include_context 'common data'

  before do
    allow_any_instance_of(UserServiceClient).to \
      receive(:fetch_developer_id).and_return(nil)

    allow_any_instance_of(Api::V1::CategoriesController).to \
      receive(:developer_id).and_return(nil)
  end

  let(:valid_attributes) do
    {
      name: 'Home Appliance',
      description: 'Everything home appliance goes here'
    }
  end

  let(:invalid_attributes) do
    { name: '', description: '' } # no category name and description
  end

  context 'with valid developer token: using first dev' do
    let(:expected_developer_id) { developers.dig(:first, :id) }

    before do
      allow_any_instance_of(UserServiceClient).to \
        receive(:fetch_developer_id).and_return(expected_developer_id)

      allow_any_instance_of(Api::V1::CategoriesController).to \
        receive(:developer_id).and_return(expected_developer_id)
    end

    # ensure that there are two categories at the start of the test
    it 'starts with 2 categories in the database' do
      expect(Category.count).to eq(2)
    end

    describe "GET /index" do
      it "renders a successful response" do
        get api_v1_categories_url, headers: valid_headers[:first_dev]
        expect(response).to be_successful
      end

      it 'gets the right developer ID from the user service' do
        get api_v1_categories_url, headers: valid_headers[:first_dev]

        data = response_body[:data][0]
        expect(data.dig(:attributes, :developer_id)).to \
          eq(expected_developer_id)
      end

      it "contains data object for actual response data" do
        get api_v1_categories_url, headers: valid_headers[:first_dev]
        expect(response_body).to have_key(:data)
      end

      it 'contains RESTful meta information' do
        get api_v1_categories_url, headers: valid_headers[:first_dev]
        expect(response).to have_http_status(:ok)

        expect(response_body).to have_key(:meta)
        meta = response_body[:meta]

        expect(meta).to include(:message, :total_count, :current_count)
      end

      describe 'Pagination' do
        it 'contains pagination links' do
          get api_v1_categories_url, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body).to have_key(:links)

          pagination_links = response_body[:links]

          expect(pagination_links).to have_key(:first)
          expect(pagination_links).to have_key(:last)
          expect(pagination_links).to have_key(:prev)
          expect(pagination_links).to have_key(:next)

          # let's validate that the pagination links are correct and contains
          # the right keys
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
                                     headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)

          # the first developer has only one category created so far
          expect(response_body.dig(:meta, :current_count)).to eq(1)
          expect(response_body.dig(:meta, :total_count)).to eq(1)
          expect(response_body[:data].size).to eq(1)
        end

        it 'limits the page size to 100' do
          get api_v1_categories_url, params: { page_size: 101 },
                                     headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body[:meta][:current_count]).to be <= 100
          expect(response_body.dig(:links, :first)).to eq(
            "#{request.base_url}/api/v1/categories?page=1&page_size=100"
          )
        end
      end

      describe 'Response data body' do
        let!(:categories) { [Category.first, Category.last] }

        it 'has all the required and follows the JSONAPI standard' do
          get api_v1_categories_url, headers: valid_headers[:first_dev]

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
          get api_v1_categories_url, headers: valid_headers[:first_dev]

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
          get api_v1_categories_url, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          response_data = response_body[:data]

          expect(response_data).not_to be_empty

          response_data.each do |data|
            expect(data.dig(:attributes, :developer_id)).to eq(
              developers.dig(:first, :id)
            )
          end
        end
      end

      context 'with query parameters in the request path' do
        before do
          Category.create!(
            name: 'Body lotions', description: 'Skin care products',
            developer_id: developers.dig(:first, :id)
          ).reload
        end

        context 'with filters based on the name' do
          it 'filters the categories based on the name' do
            get api_v1_categories_url,
                params: { name: 'lotions' },
                headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(1)

            response_data = response_body[:data]

            expect(response_data.first.dig(:attributes, :name)).to \
              eq('Body lotions')
          end

          it 'returns an empty array when no match is found' do
            get api_v1_categories_url,
                params: { name: 'blah' },
                headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(0)
          end

          it 'returns all categories when the filter is not found' do
            get api_v1_categories_url,
                params: { unknown: 'Body lotions' },
                headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(2)
          end
        end

        context "with filters based on the 'search' keyword" do
          it 'returns all categories with the searched keyword' do
            get api_v1_categories_url,
                params: { search: 'kitchen' },
                headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:ok)
            expect(response_body[:data].size).to eq(1)

            response_data = response_body[:data]

            expect(response_data.first.dig(:attributes, :name)).to \
              eq('Kitchen Appliances')
          end
        end
      end
    end

    describe "GET /show" do
      context "with the first developer's token" do
        it "renders a successful response" do
          get api_v1_category_url(first_dev_category_kitchen),
              headers: valid_headers[:first_dev]
          expect(response).to be_successful
        end

        it "contains data object for actual response data" do
          get api_v1_category_url(first_dev_category_kitchen),
              headers: valid_headers[:first_dev]
          expect(response_body).to include(:data)
        end

        it "contains the exact data for the category requested" do
          get api_v1_category_url(first_dev_category_kitchen),
              headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body[:data]).to include(:id, :type, :attributes)

          response_data = response_body[:data]

          expect(response_data.dig(:attributes, :name)).to eq(
            first_dev_category_kitchen.name
          )
          expect(response_data.dig(:attributes, :description)).to eq(
            first_dev_category_kitchen.description
          )
          expect(response_data.dig(:attributes, :developer_id)).to eq(
            first_dev_category_kitchen.developer_id
          )
        end

        it "gets a 404 when the category is not found" do
          get api_v1_category_url(UUID7.generate),
              headers: valid_headers[:first_dev]
          expect(response).to have_http_status(:not_found)
        end

        it "rejects requests from developers who do not own the category" do
          allow_any_instance_of(UserServiceClient).to \
            receive(:fetch_developer_id).and_return(
              developers.dig(:second, :id)
            )

          allow_any_instance_of(Api::V1::CategoriesController).to \
            receive(:developer_id).and_return(developers.dig(:second, :id))

          get api_v1_category_url(first_dev_category_kitchen),
              headers: valid_headers[:second_dev]

          expect(response).to have_http_status(:not_found)
        end
      end

      context "with the second developer's token" do
        before do
          allow_any_instance_of(UserServiceClient).to \
            receive(:fetch_developer_id).and_return(
              developers.dig(:second, :id)
            )

          allow_any_instance_of(Api::V1::CategoriesController).to \
            receive(:developer_id).and_return(developers.dig(:second, :id))
        end

        it "renders a successful response" do
          get api_v1_category_url(second_dev_category_computers),
              headers: valid_headers[:second_dev]

          expect(response).to be_successful
        end

        it "contains data object for actual response data" do
          get api_v1_category_url(second_dev_category_computers),
              headers: valid_headers[:second_dev]
          expect(response_body).to include(:data)
        end

        it "contains the exact data for the category requested" do
          get api_v1_category_url(second_dev_category_computers),
              headers: valid_headers[:second_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body[:data]).to include(:id, :type, :attributes)

          response_data = response_body[:data]

          expect(response_data.dig(:attributes, :name)).to eq(
            second_dev_category_computers.name
          )
          expect(response_data.dig(:attributes, :description)).to eq(
            second_dev_category_computers.description
          )
          expect(response_data.dig(:attributes, :developer_id)).to eq(
            second_dev_category_computers.developer_id
          )
        end

        it "gets a 404 when the category is not found" do
          get api_v1_category_url(UUID7.generate),
              headers: valid_headers[:second_dev]
          expect(response).to have_http_status(:not_found)
        end

        it "rejects requests from developers who do not own the category" do
          allow_any_instance_of(Api::V1::CategoriesController).to \
            receive(:developer_id).and_return(developers.dig(:first, :id))

          get api_v1_category_url(second_dev_category_computers),
              headers: valid_headers[:first_dev]

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
                   headers: valid_headers[:first_dev], as: :json
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
                       name: first_dev_category_kitchen.name,
                       description: first_dev_category_kitchen.description
                     }
                   },
                   headers: valid_headers[:first_dev], as: :json
            end.not_to change(Category, :count)

            expect(response).to have_http_status(:conflict)

            expect(response_body[:error]).to eq("Duplicate record found")
          end

          it "renders a JSON response with the newly created category" do
            post api_v1_categories_url,
                 params: {
                   category: {
                     name: 'Body Lotions',
                     description: 'This category is for skin care products'
                   }
                 },
                 headers: valid_headers[:first_dev], as: :json

            expect(response).to have_http_status(:created)
            expect(response.content_type).to include("application/json")
          end
        end

        context "with invalid parameters" do
          it "does not create a new Category" do
            expect do
              post api_v1_categories_url,
                   headers: valid_headers[:first_dev],
                   params: { api_v1_category: invalid_attributes }, as: :json
            end.to change(Category, :count).by(0)
          end

          it "renders a JSON response with errors for the new category" do
            post api_v1_categories_url,
                 params: { category: invalid_attributes },
                 headers: valid_headers[:first_dev], as: :json
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
            patch api_v1_category_url(first_dev_category_kitchen),
                  params: { category: new_attributes },
                  headers: valid_headers[:first_dev], as: :json

            first_dev_category_kitchen.reload
            expect(response).to have_http_status(:ok)

            expect(first_dev_category_kitchen.description).to eq(
              new_attributes[:description]
            )
            expect(first_dev_category_kitchen.name).to eq(new_attributes[:name])
          end

          it "renders a JSON response with the category" do
            patch api_v1_category_url(first_dev_category_kitchen),
                  params: { category: new_attributes },
                  headers: valid_headers[:first_dev], as: :json

            expect(response).to have_http_status(:ok)
            expect(response.content_type).to include("application/json")
          end

          it "rejects updates from developers who do not own the category" do
            allow_any_instance_of(Api::V1::CategoriesController).to \
              receive(:developer_id).and_return(developers.dig(:second, :id))

            patch api_v1_category_url(first_dev_category_kitchen),
                  params: { category: new_attributes },
                  headers: valid_headers[:second_dev], as: :json

            # for the sake of security, we will just tell them the item wasn't
            # found because they don't own it.
            expect(response).to have_http_status(:not_found)
          end
        end

        context "with invalid parameters" do
          it "renders a JSON response with errors for the category" do
            patch api_v1_category_url(first_dev_category_kitchen),
                  params: { category: invalid_attributes },
                  headers: valid_headers[:first_dev], as: :json
            expect(response).to have_http_status(:unprocessable_content)

            expect(response.content_type).to include("application/json")
          end
        end
      end

      describe "DELETE /destroy" do
        it "destroys the requested category if it exists" do
          expect do
            delete api_v1_category_url(first_dev_category_kitchen),
                   headers: valid_headers[:first_dev], as: :json
          end.to change(Category, :count).by(-1)

          expect(response).to have_http_status(:no_content)
        end

        it 'returns 404 when the requested category is not found' do
          expect do
            delete api_v1_category_url(UUID7.generate),
                   headers: valid_headers[:first_dev], as: :json
          end.not_to change(Category, :count)

          expect(response).to have_http_status(:not_found)
        end

        it 'returns an empty response body on success' do
          expect do
            delete api_v1_category_url(first_dev_category_kitchen),
                   headers: valid_headers[:first_dev],
                   as: :json
          end.to change(Category, :count).by(-1)

          expect(response).to have_http_status(:no_content)
          expect(response.body.empty?).to be(true)
        end

        it "rejects deletions from developers who do not own the category" do
          allow_any_instance_of(Api::V1::CategoriesController).to \
            receive(:developer_id).and_return(developers.dig(:second, :id))
          delete api_v1_category_url(first_dev_category_kitchen),
                 headers: valid_headers[:second_dev], as: :json

          # for the sake of security, we will just tell them the item wasn't
          # found because they don't own it.
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  context 'with an invalid or missing developer token' do
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

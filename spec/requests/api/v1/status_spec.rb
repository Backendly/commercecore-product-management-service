# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::Status", type: :request do
  describe "GET /show" do
    it "returns the status of the API" do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('ok')
      expect(response.body).to include('Product Management Service')
      expect(response.body).to include('v1')
      expect(response.body).to include('http://www.example.com/api/v1')
      expect(response.body).to include('connected')
      expect(response.body).to include('uptime')
    end

    it 'returns the correct environment' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:environment]).to eq('test')
    end

    it 'returns the correct timestamp' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:timestamp]).to be_present
    end

    it 'returns the correct database status' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:database_status]).to eq('connected')
    end

    it 'returns the correct uptime' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:uptime]).to be_present
    end

    it 'returns the correct base_url' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:base_url]).to eq('http://www.example.com/api/v1')
    end

    it 'returns the correct version' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:version]).to eq('v1')
    end

    it 'returns the correct service' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:service]).to eq('Product Management Service')
    end

    it 'returns the correct status' do
      get '/api/v1/status'
      expect(response).to have_http_status(:ok)
      expect(response_body[:status]).to eq('ok')
    end
  end
end

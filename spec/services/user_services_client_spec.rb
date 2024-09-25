# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserServiceClient, type: :service do
  let(:developer_token) { 'some_developer_token' }
  let(:developer_id) { 'some_developer_id' }
  let(:user_service_client) { UserServiceClient.new }
  let(:app_id) { 'some_app_id' }

  describe '#fetch_developer_id' do
    it 'returns the cached developer ID if present' do
      allow(Rails.cache).to \
        receive(:fetch).with(
          "developer:#{developer_token}"
        ).and_return(developer_id)

      result = user_service_client.fetch_developer_id(developer_token:)
      expect(result).to eq(developer_id)
    end

    it 'fetches and caches the developer ID if not cached' do
      allow(Rails.cache).to receive(:fetch).with(
        "developer:#{developer_token}"
      ).and_return(nil)
      allow(user_service_client.class).to \
        receive(:get).and_return(
          double(
            success?: true,
            parsed_response: { developer_id: }
          )
        )
      allow(Rails.cache).to receive(:fetch).with(
        "developer:#{developer_token}", expires_in: 12.hours
      ).and_yield.and_return(developer_id)

      result = user_service_client.fetch_developer_id(developer_token:)
      expect(result).to eq(developer_id)
    end

    it 'returns nil if the response is not successful' do
      allow(Rails.cache).to \
        receive(:fetch).with("developer:#{developer_token}").and_return(nil)
      allow(user_service_client.class).to \
        receive(:get).and_return(double(success?: false))

      result = user_service_client.fetch_developer_id(developer_token:)
      expect(result).to be_nil
    end
  end

  describe '#fetch_user' do
    let(:user_id) { 'some_user_id' }
    let(:user) { double }
    let(:user_cache_key) do
      "user:#{user_id}_app:#{app_id}_dev:#{developer_token}"
    end

    it 'returns the cached user if present' do
      allow(Rails.cache).to \
        receive(:fetch).with("user:#{user_id}").and_return(user)
    end

    it 'fetches and caches the user if not cached' do
      allow(Rails.cache).to \
        receive(:fetch).with(user_cache_key).and_return(nil)

      allow(user_service_client.class).to \
        receive(:get).and_return(double(success?: true, parsed_response: user))

      allow(Rails.cache).to \
        receive(:fetch).with(user_cache_key, expires_in: 12.hours)
                       .and_yield.and_return(user)

      result = user_service_client.fetch_user(
        user_id:, developer_token:, app_id:
      )
      expect(result).to eq(user)
    end

    it 'returns nil if the response is not successful' do
      allow(Rails.cache).to \
        receive(:fetch).with(user_cache_key).and_return(nil)

      allow(user_service_client.class).to \
        receive(:get).and_return(double(success?: false))

      result = user_service_client.fetch_user(
        user_id:, developer_token:, app_id:
      )
      expect(result).to be_nil
    end
  end

  describe '#fetch_app' do
    let(:app) { double }
    let(:app_cache_key) { "app:#{app_id}_#{developer_token}" }

    it 'returns the cached app if present' do
      allow(Rails.cache).to \
        receive(:fetch).with("app:#{app_id}").and_return(app)
    end

    it 'fetches and caches the app if not cached' do
      allow(Rails.cache).to \
        receive(:fetch).with(app_cache_key).and_return(nil)

      allow(user_service_client.class).to \
        receive(:get).and_return(double(success?: true, parsed_response: app))

      allow(Rails.cache).to \
        receive(:fetch).with(app_cache_key, expires_in: 12.hours)
                       .and_yield.and_return(app)

      result = user_service_client.fetch_app(app_id:, developer_token:)
      expect(result).to eq(app)
    end

    it 'returns nil if the response is not successful' do
      allow(Rails.cache).to \
        receive(:fetch).with(app_cache_key).and_return(nil)

      allow(user_service_client.class).to \
        receive(:get).and_return(double(success?: false))

      result = user_service_client.fetch_app(app_id:, developer_token:)
      expect(result).to be_nil
    end
  end
end

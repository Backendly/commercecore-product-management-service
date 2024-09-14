# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserServiceClient, type: :service do
  let(:developer_token) { 'some_developer_token' }
  let(:developer_id) { 'some_developer_id' }
  let(:user_service_client) { UserServiceClient.new }

  describe '#fetch_developer_id' do
    it 'returns the cached developer ID if present' do
      allow(Rails.cache).to \
        receive(:fetch).with(
          "developer:#{developer_token}"
        ).and_return(developer_id)

      result = user_service_client.fetch_developer_id(developer_token)
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

      result = user_service_client.fetch_developer_id(developer_token)
      expect(result).to eq(developer_id)
    end

    it 'returns nil if the response is not successful' do
      allow(Rails.cache).to \
        receive(:fetch).with("developer:#{developer_token}").and_return(nil)
      allow(user_service_client.class).to \
        receive(:get).and_return(double(success?: false))

      result = user_service_client.fetch_developer_id(developer_token)
      expect(result).to be_nil
    end
  end
end

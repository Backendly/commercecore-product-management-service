# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentStatusListenerJob, type: :job do
  include ActiveJob::TestHelper

  let(:app_id) { UUID7.generate }
  let(:product) { FactoryBot.create(:product, app_id:) }
  let(:order) { FactoryBot.create(:order, app_id:) }
  let(:order_id) { order.id }
  let(:status) { 'successful' }
  let(:redis_double) { instance_double(Redis) }
  let(:message_callback) { double('message_callback') }

  before do
    allow(Redis).to receive(:new).and_return(redis_double)

    allow(redis_double).to receive(:subscribe).and_yield(message_callback)

    allow(message_callback).to receive(:message).and_yield(
      'payment_order_status', { order_id:, status: }.to_json
    )

    allow(PaymentStatusJob).to receive(:perform_later)

    clear_enqueued_jobs
    clear_performed_jobs

    FactoryBot.create(:order_item, product:, order:)
  end

  it 'subscribes to the correct Redis channel and processes messages' do
    described_class.perform_now

    expect(PaymentStatusJob).to have_received(:perform_later)
  end

  context 'with invalid JSON' do
    it 'does not enqueue PaymentStatusJob' do
      allow(message_callback).to receive(:message).and_yield(
        'payment_order_status', 'invalid_json'
      )

      described_class.perform_now

      expect(PaymentStatusJob).not_to have_received(:perform_later)
    end

    it 'logs an invalid JSON error' do
      allow(message_callback).to receive(:message).and_yield(
        'payment_order_status', 'invalid_json'
      )

      expect(Rails.logger).to receive(:error).with('Invalid JSON: invalid_json')

      described_class.perform_now
    end
  end

  context 'when either "status" or "order" are missing' do
    it 'does not enqueue PaymentStatusJob' do
      allow(message_callback).to receive(:message).and_yield(
        'payment_order_status', { order_id: }.to_json
      )

      described_class.perform_now

      expect(PaymentStatusJob).not_to have_received(:perform_later)

      allow(message_callback).to receive(:message).and_yield(
        'payment_order_status', { status: }.to_json
      )

      described_class.perform_now

      expect(PaymentStatusJob).not_to have_received(:perform_later)
    end
  end

  it 'handles exceptions gracefully and does not crash' do
    allow(PaymentStatusJob).to receive(:perform_later).and_raise(StandardError)

    expect do
      described_class.perform_now
    end.not_to raise_error
  end

  it 'does nothing when no message is received' do
    allow(message_callback).to receive(:message).and_yield(
      'payment_order_status', nil
    )

    described_class.perform_now

    expect(PaymentStatusJob).not_to have_received(:perform_later)
  end
end

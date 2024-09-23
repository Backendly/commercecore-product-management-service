# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentStatusListenerJob, type: :job do
  let(:order_id) { '019205de-17e6-7091-acbc-f81e5787d165' }
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
  end

  it 'subscribes to the correct Redis channel and processes messages' do
    described_class.perform_now

    expect(PaymentStatusJob).to have_received(:perform_later).with(
      order_id, status
    )
  end
end

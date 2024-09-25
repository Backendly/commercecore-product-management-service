# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifyUserServiceJob, type: :job do
  # class NotifyUserServiceJob < ApplicationJob
  #   queue_as :default
  #
  #   def perform(order_id, status)
  #     order = Order.find(order_id)
  #
  #     Redis.new.publish('user_order_notification', {
  #       order_id: order.id,
  #       user_id: order.user_id,
  #       status:,
  #       total_amount: order.total_amount
  #     }.to_json)
  #   end

  describe '#perform' do
    let(:order) { FactoryBot.create(:order) }

    context 'when the order is successful' do
      it 'publishes a message' do
        expect_any_instance_of(Redis).to receive(:publish).with(
          'user_order_notification', {
            order_id: order.id,
            user_id: order.user_id,
            status: 'successful',
            total_amount: order.total_amount
          }.to_json
        )

        described_class.perform_now(order.id, 'successful')
      end
    end

    context 'when the order fails' do
      it 'publishes a message' do
        expect_any_instance_of(Redis).to receive(:publish).with(
          'user_order_notification', {
            order_id: order.id,
            user_id: order.user_id,
            status: 'failed',
            total_amount: order.total_amount
          }.to_json
        )

        described_class.perform_now(order.id, 'failed')
      end
    end

    context 'when the order is processing' do
      it 'publishes a message' do
        expect_any_instance_of(Redis).to receive(:publish).with(
          'user_order_notification', {
            order_id: order.id,
            user_id: order.user_id,
            status: 'processing',
            total_amount: order.total_amount
          }.to_json
        )

        described_class.perform_now(order.id, 'processing')
      end
    end

    context 'when the order is refunded' do
      it 'publishes a message' do
        expect_any_instance_of(Redis).to receive(:publish).with(
          'user_order_notification', {
            order_id: order.id,
            user_id: order.user_id,
            status: 'refunded',
            total_amount: order.total_amount
          }.to_json
        )

        described_class.perform_now(order.id, 'refunded')
      end
    end

    context 'when the order is not found' do
      it 'does not publish a message' do
        expect_any_instance_of(Redis).not_to receive(:publish)

        described_class.perform_now('invalid_id', 'successful')
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(
          'Order with ID: invalid_id not found'
        )

        described_class.perform_now('invalid_id', 'successful')
      end
    end
  end
end

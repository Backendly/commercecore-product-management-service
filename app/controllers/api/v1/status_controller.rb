# frozen_string_literal: true

module Api
  module V1
    # Controller for API status information
    class StatusController < ApplicationController
      skip_before_action :verify_authentication_credentials!
      before_action :ensure_database_connection

      # GET /api/v1/status
      def show
        render json: {
          status: "ok",
          service: "Product Management Service",
          version: "v1",
          timestamp: Time.now.utc,
          environment: Rails.env,
          base_url: "#{request.base_url}/api/v1",
          database_status:,
          uptime:
        }, status: :ok
      end

      private

        def database_status
          ActiveRecord::Base.connection.active? ? "connected" : "disconnected"
        end

        def uptime
          `uptime -p`.strip
        end

        def ensure_database_connection
          return if ActiveRecord::Base.connection.active?

          ActiveRecord::Base.establish_connection
          Rails.logger.info "Connected to the database"
          ActiveRecord::Base.connection.execute("SELECT 1")
        end
    end
  end
end

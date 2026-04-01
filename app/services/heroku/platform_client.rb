# frozen_string_literal: true

require 'platform-api'

module Heroku
  # Wraps the platform-api gem with authenticated access, timeout handling,
  # and mock/stub support for development/test environments without a live token.
  #
  # Real API calls are controlled by the `heroku_cost_inventory` Flipper flag.
  # Without the flag (or without a token), the client returns mock data.
  class PlatformClient
    MOCK_ENABLED_ENVS = %w[test development].freeze

    class NotConfiguredError < StandardError; end
    class ApiError < StandardError; end

    def initialize(token: nil)
      @token = token || api_token
    end

    # Returns the raw platform-api client, or nil in mock mode.
    def client
      return nil if mock_mode?

      raise NotConfiguredError, 'HEROKU_PLATFORM_API_TOKEN is not set' if @token.blank?

      @client ||= PlatformAPI.connect_oauth(@token)
    end

    def mock_mode?
      return true if MOCK_ENABLED_ENVS.include?(Rails.env) && @token.blank?
      return true unless Flipper.enabled?(:heroku_cost_inventory)

      @token.blank?
    end

    # List all apps in a given space.
    # Returns an array of app attribute hashes.
    def list_space_apps(space_name)
      if mock_mode?
        Rails.logger.info("[Heroku::PlatformClient] Mock mode — returning stub apps for space=#{space_name}")
        return mock_space_apps(space_name)
      end

      with_error_handling("list_space_apps space=#{space_name}") do
        client.space_app.list(space_name)
      end
    end

    # Get formation (process types) for an app.
    def list_formation(app_id_or_name)
      return mock_formation(app_id_or_name) if mock_mode?

      with_error_handling("list_formation app=#{app_id_or_name}") do
        client.formation.list(app_id_or_name)
      end
    end

    # Get add-ons for an app.
    def list_addons(app_id_or_name)
      return mock_addons(app_id_or_name) if mock_mode?

      with_error_handling("list_addons app=#{app_id_or_name}") do
        client.addon.list_by_app(app_id_or_name)
      end
    end

    # Get pipeline couplings to determine pipeline_stage for an app.
    def list_pipeline_couplings_for_app(app_id_or_name)
      return mock_pipeline_couplings(app_id_or_name) if mock_mode?

      with_error_handling("list_pipeline_couplings app=#{app_id_or_name}") do
        client.pipeline_coupling.list_by_app(app_id_or_name)
      end
    rescue ApiError
      # Some apps have no pipeline couplings — not an error
      []
    end

    private

    def api_token
      (Rails.application.credentials.dig(:heroku, :platform_api_token) ||
        ENV.fetch('HEROKU_PLATFORM_API_TOKEN', nil)).to_s.strip
    end

    def with_error_handling(context)
      yield
    rescue StandardError => e
      sanitized = e.message.gsub(@token.to_s, '[REDACTED]')
      Rails.logger.error("[Heroku::PlatformClient] #{context} error=#{sanitized}")
      raise ApiError, "Heroku API error in #{context}: #{sanitized}"
    end

    # --- Mock data for development/test/stub mode ---

    def mock_space_apps(space_name)
      [
        {
          'id' => 'mock-app-id-001',
          'name' => "#{space_name}-web-production",
          'space' => { 'name' => space_name },
        },
        {
          'id' => 'mock-app-id-002',
          'name' => "#{space_name}-web-staging",
          'space' => { 'name' => space_name },
        },
        {
          'id' => 'mock-app-id-003',
          'name' => "#{space_name}-worker-production",
          'space' => { 'name' => space_name },
        },
      ]
    end

    def mock_formation(app_id_or_name)
      [
        {
          'type' => 'web',
          'size' => 'standard-2x',
          'quantity' => 2,
        },
      ]
    end

    def mock_addons(app_id_or_name)
      [
        {
          'addon_service' => { 'name' => 'heroku-postgresql' },
          'plan' => { 'name' => 'heroku-postgresql:standard-0' },
        },
      ]
    end

    def mock_pipeline_couplings(app_id_or_name)
      stage = if app_id_or_name.to_s.include?('staging')
                'staging'
              elsif app_id_or_name.to_s.include?('production')
                'production'
              else
                'development'
              end
      [{ 'stage' => stage, 'pipeline' => { 'id' => 'mock-pipeline-id' } }]
    end
  end
end

# frozen_string_literal: true

module Heroku
  # Fetches and normalises inventory for all apps in a Heroku space.
  # Returns a list of enriched app attribute hashes that include
  # pipeline_stage and environment classification.
  class SpaceInventoryService
    Result = Struct.new(:apps, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    AppInfo = Struct.new(
      :app_id,
      :app_name,
      :pipeline_id,
      :pipeline_stage,
      :environment,
      :formation,
      :addons,
      keyword_init: true,
    )

    def self.fetch(space_name:, client: nil)
      new(space_name: space_name, client: client).fetch
    end

    def initialize(space_name:, client: nil)
      @space_name = space_name
      @client = client || Heroku::PlatformClient.new
    end

    def fetch
      apps = @client.list_space_apps(@space_name)
      results = []
      errors = []

      apps.each do |app|
        app_id   = app['id'] || app.dig('app', 'id')
        app_name = app['name'] || app.dig('app', 'name')

        couplings     = fetch_couplings(app_id || app_name)
        pipeline_id   = couplings.first&.dig('pipeline', 'id')
        pipeline_stage = couplings.first&.dig('stage')
        environment = Heroku::EnvironmentClassifier.classify(
          pipeline_stage: pipeline_stage,
          app_name: app_name,
        )

        formation = fetch_formation(app_id || app_name)
        addons    = fetch_addons(app_id || app_name)

        results << AppInfo.new(
          app_id: app_id,
          app_name: app_name,
          pipeline_id: pipeline_id,
          pipeline_stage: pipeline_stage,
          environment: environment,
          formation: formation,
          addons: addons,
        )
      rescue Heroku::PlatformClient::ApiError => e
        Rails.logger.warn("[Heroku::SpaceInventoryService] Error fetching app #{app_name}: #{e.message}")
        errors << { app_name: app_name, error: e.message }
      end

      Result.new(apps: results, errors: errors)
    end

    private

    def fetch_couplings(app_id_or_name)
      @client.list_pipeline_couplings_for_app(app_id_or_name)
    rescue StandardError
      []
    end

    def fetch_formation(app_id_or_name)
      @client.list_formation(app_id_or_name)
    rescue StandardError
      []
    end

    def fetch_addons(app_id_or_name)
      @client.list_addons(app_id_or_name)
    rescue StandardError
      []
    end
  end
end

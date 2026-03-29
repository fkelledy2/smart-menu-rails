# frozen_string_literal: true

require 'test_helper'

module MenuExperiments
  class ExposureLoggerTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    def setup
      @menu = menus(:one)
      @dining_session = dining_sessions(:valid_session)

      @v1 = MenuVersion.create!(
        menu: @menu,
        version_number: 400,
        snapshot_json: { schema_version: 1 },
        is_active: false,
      )
      @v2 = MenuVersion.create!(
        menu: @menu,
        version_number: 401,
        snapshot_json: { schema_version: 1 },
        is_active: false,
      )

      @experiment = MenuExperiment.create!(
        menu: @menu,
        control_version: @v1,
        variant_version: @v2,
        allocation_pct: 50,
        starts_at: 1.hour.from_now,
        ends_at: 24.hours.from_now,
        status: :active,
      )
    end

    def teardown
      @experiment.destroy! if @experiment&.persisted?
      @v1.destroy! if @v1&.persisted?
      @v2.destroy! if @v2&.persisted?
    end

    test 'enqueues MenuExperimentExposureJob' do
      assert_enqueued_with(job: MenuExperimentExposureJob) do
        ExposureLogger.log(@dining_session, @experiment, @v1)
      end
    end

    test 'does not raise when job enqueue fails' do
      MenuExperimentExposureJob.stub(:perform_later, ->(*) { raise 'queue down' }) do
        assert_nothing_raised do
          ExposureLogger.log(@dining_session, @experiment, @v1)
        end
      end
    end
  end
end

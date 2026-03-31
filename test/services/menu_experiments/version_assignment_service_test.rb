# frozen_string_literal: true

require 'test_helper'

module MenuExperiments
  class VersionAssignmentServiceTest < ActiveSupport::TestCase
    def setup
      @menu = menus(:one)

      @v1 = MenuVersion.create!(
        menu: @menu,
        version_number: 300,
        snapshot_json: { schema_version: 1 },
        is_active: false,
      )
      @v2 = MenuVersion.create!(
        menu: @menu,
        version_number: 301,
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

    test 'returns control or variant version' do
      session = DiningSession.new(session_token: 'a' * 64)
      result = VersionAssignmentService.assign(
        dining_session: session,
        menu_experiment: @experiment,
      )
      assert [result], [@experiment.control_version, @experiment.variant_version]
    end

    test 'assignment is deterministic for the same token' do
      session = DiningSession.new(session_token: 'b' * 64)

      results = Array.new(5) do
        VersionAssignmentService.assign(
          dining_session: session,
          menu_experiment: @experiment,
        )
      end

      assert results.map(&:id).uniq.length == 1, 'Assignment should be deterministic'
    end

    test 'different session tokens can produce different assignments' do
      # With many different tokens one side must appear at least once
      # Use tokens that are known to map to different buckets
      results = Array.new(100) do |i|
        session = DiningSession.new(session_token: i.to_s.ljust(64, '0'))
        VersionAssignmentService.assign(
          dining_session: session,
          menu_experiment: @experiment,
        )
      end

      version_ids = results.map(&:id).uniq
      assert version_ids.length > 1, 'Expected both control and variant to be assigned across many tokens'
    end

    test 'with 1% allocation almost all sessions go to control' do
      @experiment.update_columns(status: 0) # draft to allow update
      @experiment.update_columns(allocation_pct: 1, status: 1)

      variant_count = 0
      200.times do |i|
        session = DiningSession.new(session_token: i.to_s.ljust(64, '0'))
        result = VersionAssignmentService.assign(
          dining_session: session,
          menu_experiment: @experiment,
        )
        variant_count += 1 if result.id == @v2.id
      end

      # With 1% allocation, over 200 runs we expect ~2 variant assignments
      # Allow up to 10 for randomness
      assert variant_count <= 10, "Expected few variant assignments with 1% allocation, got #{variant_count}"
    end

    test 'with 99% allocation almost all sessions go to variant' do
      @experiment.update_columns(status: 0)
      @experiment.update_columns(allocation_pct: 99, status: 1)

      variant_count = 0
      200.times do |i|
        session = DiningSession.new(session_token: i.to_s.ljust(64, '0'))
        result = VersionAssignmentService.assign(
          dining_session: session,
          menu_experiment: @experiment,
        )
        variant_count += 1 if result.id == @v2.id
      end

      assert variant_count >= 190, "Expected most variant assignments with 99% allocation, got #{variant_count}"
    end

    test 'does not write to the database' do
      session = DiningSession.new(session_token: 'c' * 64)
      assert_no_difference 'ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM menu_experiment_exposures").first.values.first.to_i' do
        VersionAssignmentService.assign(
          dining_session: session,
          menu_experiment: @experiment,
        )
      end
    end
  end
end

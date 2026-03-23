# frozen_string_literal: true

require 'test_helper'

class MaterializedViewRefreshJobTest < ActiveSupport::TestCase
  # =========================================================================
  # refresh a specific view
  # =========================================================================

  test 'calls MaterializedViewService.refresh_view when view_name provided' do
    called_with = nil

    MaterializedViewService.stub(:refresh_view, lambda { |name, **_opts|
      called_with = name
      { success: true, duration: 0.5 }
    },) do
      MaterializedViewRefreshJob.new.perform('dw_orders_mv')
    end

    assert_equal 'dw_orders_mv', called_with
  end

  test 'raises when specific view refresh fails' do
    MaterializedViewService.stub(:refresh_view, ->(_name, **_opts) { { success: false, error: 'PG error' } }) do
      assert_raises(StandardError) do
        MaterializedViewRefreshJob.new.perform('dw_orders_mv')
      end
    end
  end

  # =========================================================================
  # refresh by priority
  # =========================================================================

  test 'calls MaterializedViewService.refresh_by_priority when priority_level provided' do
    called_priority = nil

    MaterializedViewService.stub(
      :refresh_by_priority,
      lambda { |priority, **_opts|
        called_priority = priority
        { 'view_a' => { success: true } }
      },
    ) do
      MaterializedViewRefreshJob.new.perform(nil, 'low')
    end

    assert_equal :low, called_priority
  end

  test 'raises when high-priority view refresh has failures' do
    MaterializedViewService.stub(
      :refresh_by_priority,
      ->(_priority, **_opts) { { 'critical_view' => { success: false, error: 'err' } } },
    ) do
      assert_raises(StandardError) do
        MaterializedViewRefreshJob.new.perform(nil, 'high')
      end
    end
  end

  test 'does not raise for low-priority failures' do
    MaterializedViewService.stub(
      :refresh_by_priority,
      ->(_priority, **_opts) { { 'view_b' => { success: false, error: 'err' } } },
    ) do
      assert_nothing_raised do
        MaterializedViewRefreshJob.new.perform(nil, 'low')
      end
    end
  end

  # =========================================================================
  # refresh stale views (default path)
  # =========================================================================

  test 'calls views_needing_refresh when no arguments provided and skips refresh when result is empty' do
    refresh_called = false

    MaterializedViewService.stub(:views_needing_refresh, []) do
      MaterializedViewService.stub(:refresh_view, lambda { |_name, **_opts|
        refresh_called = true
        { success: true }
      },) do
        MaterializedViewRefreshJob.new.perform
      end
    end

    assert_equal false, refresh_called, 'Should not refresh any views when none are stale'
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      MaterializedViewRefreshJob.perform_later
    end
  end
end

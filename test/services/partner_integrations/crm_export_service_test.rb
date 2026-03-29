# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrations::CrmExportServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'returns expected top-level keys' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_includes result.keys, :restaurant_id
    assert_includes result.keys, :window_minutes
    assert_includes result.keys, :generated_at
    assert_includes result.keys, :avg_time_to_bill_seconds
    assert_includes result.keys, :avg_session_duration_seconds
    assert_includes result.keys, :repeat_table_count
    assert_includes result.keys, :order_pacing
  end

  test 'restaurant_id matches the restaurant' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_equal @restaurant.id, result[:restaurant_id]
  end

  test 'order_pacing is an array' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_kind_of Array, result[:order_pacing]
  end

  test 'repeat_table_count is an integer' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_kind_of Integer, result[:repeat_table_count]
  end

  test 'window_minutes defaults to 60' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_equal 60, result[:window_minutes]
  end

  test 'window_minutes can be overridden' do
    result = PartnerIntegrations::CrmExportService.new(
      restaurant: @restaurant,
      window_minutes: 15,
    ).call
    assert_equal 15, result[:window_minutes]
  end

  test 'clamps window_minutes to maximum 1440' do
    result = PartnerIntegrations::CrmExportService.new(
      restaurant: @restaurant,
      window_minutes: 5000,
    ).call
    assert_equal 1440, result[:window_minutes]
  end

  test 'avg_time_to_bill_seconds is nil when no billrequested orders exist' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_nil result[:avg_time_to_bill_seconds]
  end

  test 'avg_session_duration_seconds is nil when no paid orders exist' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_nil result[:avg_session_duration_seconds]
  end

  test 'generated_at is an ISO8601 string' do
    result = PartnerIntegrations::CrmExportService.new(restaurant: @restaurant).call
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:generated_at])
  end
end

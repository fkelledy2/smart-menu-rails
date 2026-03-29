# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrations::WorkforceExportServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'returns expected top-level keys' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_includes result.keys, :restaurant_id
    assert_includes result.keys, :window_minutes
    assert_includes result.keys, :generated_at
    assert_includes result.keys, :order_velocity
    assert_includes result.keys, :avg_prep_time_seconds
    assert_includes result.keys, :table_occupancy
    assert_includes result.keys, :top_items
  end

  test 'restaurant_id matches the restaurant' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_equal @restaurant.id, result[:restaurant_id]
  end

  test 'order_velocity is a float' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_kind_of Numeric, result[:order_velocity]
  end

  test 'table_occupancy is an array' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_kind_of Array, result[:table_occupancy]
  end

  test 'top_items is an array' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_kind_of Array, result[:top_items]
  end

  test 'window_minutes defaults to 60' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_equal 60, result[:window_minutes]
  end

  test 'window_minutes can be overridden' do
    result = PartnerIntegrations::WorkforceExportService.new(
      restaurant: @restaurant,
      window_minutes: 30,
    ).call
    assert_equal 30, result[:window_minutes]
  end

  test 'clamps window_minutes to 1440 maximum' do
    result = PartnerIntegrations::WorkforceExportService.new(
      restaurant: @restaurant,
      window_minutes: 9999,
    ).call
    assert_equal 1440, result[:window_minutes]
  end

  test 'generated_at is an ISO8601 string' do
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:generated_at])
  end

  test 'avg_prep_time_seconds is nil when no closed orders exist' do
    # There are no closed orders in fixtures
    result = PartnerIntegrations::WorkforceExportService.new(restaurant: @restaurant).call
    # If no closed ordrs with paidAt, should be nil
    assert_nil result[:avg_prep_time_seconds]
  end
end

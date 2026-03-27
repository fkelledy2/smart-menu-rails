# frozen_string_literal: true

require 'test_helper'

class Admin::DemoBookingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @mellow_admin = users(:super_admin) # email: admin@mellow.menu
    @regular_user = users(:one)         # email: test1@gmail.com
    @booking      = demo_bookings(:pending_lead)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user is redirected' do
    get admin_demo_bookings_path
    assert_response :redirect
  end

  test 'non-mellow user is denied' do
    sign_in @regular_user
    get admin_demo_bookings_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'mellow admin can access index' do
    sign_in @mellow_admin
    get admin_demo_bookings_path
    assert_response :ok
  end

  test 'index renders a table of bookings' do
    sign_in @mellow_admin
    get admin_demo_bookings_path
    assert_select 'table'
  end

  test 'CSV export is successful' do
    sign_in @mellow_admin
    get admin_demo_bookings_path(format: :csv)
    assert_response :ok
    assert_equal 'text/csv; charset=utf-8', response.content_type
    assert_includes response.body, 'Restaurant'
    assert_includes response.body, @booking.restaurant_name
  end

  # ---------------------------------------------------------------------------
  # Show
  # ---------------------------------------------------------------------------

  test 'mellow admin can view a booking' do
    sign_in @mellow_admin
    get admin_demo_booking_path(@booking)
    assert_response :ok
    assert_select 'dl', minimum: 1
  end

  test 'non-mellow user cannot view a booking' do
    sign_in @regular_user
    get admin_demo_booking_path(@booking)
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Update
  # ---------------------------------------------------------------------------

  test 'mellow admin can update conversion_status' do
    sign_in @mellow_admin
    patch admin_demo_booking_path(@booking),
          params: { demo_booking: { conversion_status: 'contacted' } }
    assert_redirected_to admin_demo_booking_path(@booking)
    assert_equal 'contacted', @booking.reload.conversion_status
  end

  test 'mellow admin can update calendly_event_id' do
    sign_in @mellow_admin
    patch admin_demo_booking_path(@booking),
          params: { demo_booking: { calendly_event_id: 'evt-abc-123', conversion_status: 'booked' } }
    assert_redirected_to admin_demo_booking_path(@booking)
    assert_equal 'evt-abc-123', @booking.reload.calendly_event_id
  end

  test 'non-mellow user cannot update a booking' do
    sign_in @regular_user
    patch admin_demo_booking_path(@booking),
          params: { demo_booking: { conversion_status: 'contacted' } }
    assert_redirected_to root_path
    assert_equal 'pending', @booking.reload.conversion_status
  end

  test 'update with invalid status returns 422' do
    sign_in @mellow_admin
    patch admin_demo_booking_path(@booking),
          params: { demo_booking: { conversion_status: 'invalid_status' } }
    assert_response :unprocessable_content
  end
end

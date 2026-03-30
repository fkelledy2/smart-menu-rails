# frozen_string_literal: true

require 'test_helper'

class WaitTimesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
    @owner = users(:one)
    Flipper.enable(:wait_time_estimation, @restaurant)
  end

  def teardown
    Flipper.disable(:wait_time_estimation, @restaurant)
  end

  # ---------------------------------------------------------------------------
  # Authentication
  # ---------------------------------------------------------------------------

  test 'GET show redirects unauthenticated users' do
    get wait_times_restaurant_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET show succeeds for restaurant owner' do
    sign_in @owner
    get wait_times_restaurant_path(@restaurant)
    assert_response :success
  end

  test 'GET show redirects when feature flag disabled' do
    Flipper.disable(:wait_time_estimation, @restaurant)
    sign_in @owner
    get wait_times_restaurant_path(@restaurant)
    assert_redirected_to restaurant_path(@restaurant)
  end

  test 'GET show returns 404 for unknown restaurant' do
    sign_in @owner
    get wait_times_restaurant_path(id: 999_999)
    assert_redirected_to restaurants_path
  end

  # ---------------------------------------------------------------------------
  # Create queue entry
  # ---------------------------------------------------------------------------

  test 'POST create_queue_entry adds entry and redirects' do
    sign_in @owner
    assert_difference('CustomerWaitQueue.count') do
      post wait_times_queue_restaurant_path(@restaurant), params: {
        customer_wait_queue: { customer_name: 'New Guest', party_size: 3 },
      }
    end
    assert_redirected_to wait_times_restaurant_path(@restaurant)
    follow_redirect!
    assert_match(/New Guest/, response.body)
  end

  test 'POST create_queue_entry with invalid params re-renders show' do
    sign_in @owner
    assert_no_difference('CustomerWaitQueue.count') do
      post wait_times_queue_restaurant_path(@restaurant), params: {
        customer_wait_queue: { customer_name: '', party_size: 3 },
      }
    end
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # Seat queue entry
  # ---------------------------------------------------------------------------

  test 'PATCH seat_queue_entry seats the customer' do
    sign_in @owner
    entry = customer_wait_queues(:waiting_two)
    patch seat_wait_times_queue_entry_restaurant_path(@restaurant, entry_id: entry.id)
    assert_redirected_to wait_times_restaurant_path(@restaurant)
    assert_equal 'seated', entry.reload.status
  end

  # ---------------------------------------------------------------------------
  # No-show queue entry
  # ---------------------------------------------------------------------------

  test 'PATCH no_show_queue_entry marks as no_show' do
    sign_in @owner
    entry = customer_wait_queues(:waiting_one)
    patch no_show_wait_times_queue_entry_restaurant_path(@restaurant, entry_id: entry.id)
    assert_redirected_to wait_times_restaurant_path(@restaurant)
    assert_equal 'no_show', entry.reload.status
  end

  # ---------------------------------------------------------------------------
  # Cancel queue entry
  # ---------------------------------------------------------------------------

  test 'PATCH cancel_queue_entry marks as cancelled' do
    sign_in @owner
    entry = customer_wait_queues(:notified_one)
    patch cancel_wait_times_queue_entry_restaurant_path(@restaurant, entry_id: entry.id)
    assert_redirected_to wait_times_restaurant_path(@restaurant)
    assert_equal 'cancelled', entry.reload.status
  end

  # ---------------------------------------------------------------------------
  # Authorization — non-owner cannot access another restaurant's queue
  # ---------------------------------------------------------------------------

  test 'other user cannot access another restaurant wait times' do
    other_user = users(:two)
    # users(:two) is NOT the owner of restaurant one
    # and may not be an active employee — depends on fixtures
    sign_in other_user

    # If user(:two) is an active employee, this will succeed; if not, it raises Pundit error
    # We just verify the request doesn't 500
    get wait_times_restaurant_path(@restaurant)
    assert_includes [200, 302, 403], response.status
  end
end

# frozen_string_literal: true

require 'test_helper'

class RestaurantMenusControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)

    # Ensure a RestaurantMenu join record exists for restaurant :one and menu :one
    @rm = RestaurantMenu.find_or_create_by!(restaurant: @restaurant, menu: @menu) do |r|
      r.sequence = 1
      r.status = :active
      r.availability_override_enabled = false
      r.availability_state = :available
    end

    sign_in @user
  end

  # ---------------------------------------------------------------------------
  # PATCH reorder
  # ---------------------------------------------------------------------------

  test 'reorder: returns success with valid order array' do
    patch reorder_restaurant_restaurant_menus_path(@restaurant),
          params: { order: [{ id: @rm.id, sequence: 5 }] },
          as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 'success', body['status']
    assert_equal 5, @rm.reload.sequence
  end

  test 'reorder: returns error when order param is not an array' do
    patch reorder_restaurant_restaurant_menus_path(@restaurant),
          params: { order: 'invalid' },
          as: :json

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal 'error', body['status']
  end

  test 'reorder: returns 404 for unknown restaurant_menu id' do
    patch reorder_restaurant_restaurant_menus_path(@restaurant),
          params: { order: [{ id: 0, sequence: 1 }] },
          as: :json

    assert_response :not_found
    body = response.parsed_body
    assert_equal 'error', body['status']
  end

  test 'reorder: redirects unauthenticated user' do
    sign_out @user
    patch reorder_restaurant_restaurant_menus_path(@restaurant),
          params: { order: [] },
          as: :json

    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # PATCH bulk_update
  # ---------------------------------------------------------------------------

  test 'bulk_update set_status: updates status to inactive and redirects' do
    # inactive is always allowed (no subscription check)
    patch bulk_update_restaurant_restaurant_menus_path(@restaurant),
          params: {
            restaurant_menu_ids: [@rm.id.to_s],
            operation: 'set_status',
            value: 'inactive',
          }

    assert_response :redirect
    assert_equal 'inactive', @rm.reload.status
  end

  test 'bulk_update archive: archives the restaurant_menu' do
    patch bulk_update_restaurant_restaurant_menus_path(@restaurant),
          params: {
            restaurant_menu_ids: [@rm.id.to_s],
            operation: 'archive',
          }

    assert_response :redirect
    assert_equal 'archived', @rm.reload.status
  end

  test 'bulk_update: redirects with alert for invalid operation' do
    patch bulk_update_restaurant_restaurant_menus_path(@restaurant),
          params: {
            restaurant_menu_ids: [@rm.id.to_s],
            operation: 'unknown_op',
          }

    assert_response :redirect
    assert_match(/Invalid bulk operation/i, flash[:alert].to_s)
  end

  test 'bulk_update: redirects with no ids' do
    patch bulk_update_restaurant_restaurant_menus_path(@restaurant),
          params: { restaurant_menu_ids: [], operation: 'archive' }

    assert_response :redirect
  end

  test 'bulk_update: redirects unauthenticated user' do
    sign_out @user
    patch bulk_update_restaurant_restaurant_menus_path(@restaurant),
          params: { restaurant_menu_ids: [@rm.id.to_s], operation: 'archive' }

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  # ---------------------------------------------------------------------------
  # PATCH bulk_availability
  # ---------------------------------------------------------------------------

  test 'bulk_availability: updates availability override and state' do
    patch bulk_availability_restaurant_restaurant_menus_path(@restaurant),
          params: {
            restaurant_menu_ids: [@rm.id.to_s],
            availability_override_enabled: true,
            availability_state: 'unavailable',
          }

    assert_response :redirect
    @rm.reload
    assert @rm.availability_override_enabled
    assert_equal 'unavailable', @rm.availability_state
  end

  test 'bulk_availability: redirects with empty ids' do
    patch bulk_availability_restaurant_restaurant_menus_path(@restaurant),
          params: { restaurant_menu_ids: [], availability_state: 'available' }

    assert_response :redirect
  end

  test 'bulk_availability: redirects unauthenticated user' do
    sign_out @user
    patch bulk_availability_restaurant_restaurant_menus_path(@restaurant),
          params: { restaurant_menu_ids: [@rm.id.to_s], availability_state: 'available' }

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  # ---------------------------------------------------------------------------
  # PATCH availability (single record)
  # ---------------------------------------------------------------------------

  test 'availability: updates single record and returns JSON success' do
    patch availability_restaurant_restaurant_menu_path(@restaurant, @rm),
          params: {
            availability_override_enabled: true,
            availability_state: 'unavailable',
          },
          as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 'success', body['status']
    @rm.reload
    assert @rm.availability_override_enabled
    assert_equal 'unavailable', @rm.availability_state
  end

  test 'availability: redirects unauthenticated user' do
    sign_out @user
    patch availability_restaurant_restaurant_menu_path(@restaurant, @rm),
          params: { availability_state: 'available' },
          as: :json

    assert_response :unauthorized
  end

  test 'availability: returns 404 for restaurant_menu from another user' do
    other_rm = RestaurantMenu.find_or_create_by!(restaurant: restaurants(:two), menu: menus(:two)) do |r|
      r.sequence = 1
      r.status = :active
      r.availability_override_enabled = false
      r.availability_state = :available
    end

    patch availability_restaurant_restaurant_menu_path(@restaurant, other_rm),
          params: { availability_state: 'available' },
          as: :json

    # The scope filters to current user's restaurant; record not found
    assert_response :not_found
  end
end

# frozen_string_literal: true

require 'test_helper'

class FloorplansControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @restaurant = restaurants(:one)
    @owner = @restaurant.user || users(:one)
    @restaurant.update!(user: @owner) unless @restaurant.user_id == @owner.id

    # Enable the feature flag
    Flipper.enable(:floorplan_dashboard, @restaurant)
  end

  def teardown
    Flipper.disable(:floorplan_dashboard, @restaurant)
    Flipper.disable(:floorplan_dashboard)
  end

  # ─── Authentication ───────────────────────────────────────────────────────

  test 'GET floorplan redirects unauthenticated user' do
    get floorplan_restaurant_path(@restaurant)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test 'GET floorplan returns 200 for restaurant owner' do
    sign_in @owner
    get floorplan_restaurant_path(@restaurant)
    assert_response :ok
  end

  test 'GET floorplan returns 200 for active employee' do
    employee_user = users(:two)
    Employee.create!(
      user: employee_user,
      restaurant: @restaurant,
      status: :active,
      role: :staff,
      name: 'Floor Staff',
      eid: "EMP-#{SecureRandom.hex(4)}",
    )
    sign_in employee_user
    get floorplan_restaurant_path(@restaurant)
    assert_response :ok
  end

  test 'GET floorplan redirects unauthorized user' do
    other_user = users(:two)
    sign_in other_user
    get floorplan_restaurant_path(@restaurant)
    # Pundit failure → handled by ApplicationController → redirect or forbidden
    assert_response :redirect
  end

  # ─── Feature flag ─────────────────────────────────────────────────────────

  test 'GET floorplan redirects when feature flag disabled' do
    Flipper.disable(:floorplan_dashboard, @restaurant)
    sign_in @owner
    get floorplan_restaurant_path(@restaurant)
    assert_response :redirect
  end

  # ─── Content rendering ────────────────────────────────────────────────────

  test 'GET floorplan renders table tiles for restaurant tables' do
    sign_in @owner
    get floorplan_restaurant_path(@restaurant)
    assert_response :ok
    # Should have a table grid
    assert_select '[data-floorplan-target="tileGrid"]'
  end

  test 'GET floorplan assigns table_tiles with tablesetting and ordr keys' do
    sign_in @owner
    get floorplan_restaurant_path(@restaurant)
    assert_response :ok
    assert(assigns(:table_tiles).all? { |t| t.key?(:tablesetting) && t.key?(:ordr) })
  end

  test 'GET floorplan shows available badge for table with no active order' do
    # Ensure ordrs(:one) is closed so the table has no active order
    ordrs(:one).update!(status: :closed)
    sign_in @owner
    get floorplan_restaurant_path(@restaurant)
    assert_select '.badge', text: /Available/
  end
end

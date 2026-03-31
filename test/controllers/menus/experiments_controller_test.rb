# frozen_string_literal: true

require 'test_helper'

module Menus
  class ExperimentsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @owner = users(:one)
      @other_user = users(:two)
      @restaurant = restaurants(:one)
      @menu = menus(:one)

      # Give owner a pro plan
      @pro_plan = plans(:pro)
      @owner.update_columns(plan_id: @pro_plan.id)

      # Enable Flipper flag
      Flipper.enable(:menu_experiments, @restaurant)

      # Ensure a RestaurantMenu join record exists so set_menu can find the menu
      @restaurant_menu = RestaurantMenu.find_or_create_by!(
        restaurant: @restaurant,
        menu: @menu,
      )

      @v1 = MenuVersion.create!(
        menu: @menu,
        version_number: 800,
        snapshot_json: { schema_version: 1 },
        is_active: false,
      )
      @v2 = MenuVersion.create!(
        menu: @menu,
        version_number: 801,
        snapshot_json: { schema_version: 1 },
        is_active: false,
      )
    end

    def teardown
      MenuExperiment.where(menu: @menu).where('control_version_id IN (?) OR variant_version_id IN (?)', [@v1.id, @v2.id], [@v1.id, @v2.id]).each do |e|
        e.menu_experiment_exposures.delete_all
        e.delete
      end
      @v1.destroy! if @v1&.persisted?
      @v2.destroy! if @v2&.persisted?
      @restaurant_menu&.destroy!
      Flipper.disable(:menu_experiments, @restaurant)
      @owner.update_columns(plan_id: plans(:one).id)
    end

    # === Index ===

    test 'GET index redirects unauthenticated' do
      get restaurant_menu_experiments_path(@restaurant, @menu)
      assert_redirected_to new_user_session_path
    end

    test 'GET index succeeds for owner on pro plan' do
      sign_in @owner
      get restaurant_menu_experiments_path(@restaurant, @menu)
      assert_response :success
    end

    test 'GET index is forbidden for other user' do
      sign_in @other_user
      get restaurant_menu_experiments_path(@restaurant, @menu)
      # rescue_from Pundit::NotAuthorizedError in ApplicationController redirects
      # rather than propagating the exception, so we assert the redirect response.
      assert_response :redirect
    end

    # === New ===

    test 'GET new succeeds for owner on pro plan' do
      sign_in @owner
      get new_restaurant_menu_experiment_path(@restaurant, @menu)
      assert_response :success
    end

    test 'GET new redirects unauthenticated' do
      get new_restaurant_menu_experiment_path(@restaurant, @menu)
      assert_redirected_to new_user_session_path
    end

    # === Create ===

    test 'POST create creates experiment' do
      sign_in @owner
      assert_difference 'MenuExperiment.count', 1 do
        post restaurant_menu_experiments_path(@restaurant, @menu), params: {
          menu_experiment: {
            control_version_id: @v1.id,
            variant_version_id: @v2.id,
            allocation_pct: 40,
            starts_at: 2.hours.from_now.strftime('%Y-%m-%dT%H:%M'),
            ends_at: 48.hours.from_now.strftime('%Y-%m-%dT%H:%M'),
            status: 'draft',
          },
        }
      end
      assert_redirected_to restaurant_menu_experiments_path(@restaurant, @menu)
    end

    test 'POST create fails with invalid params' do
      sign_in @owner
      assert_no_difference 'MenuExperiment.count' do
        post restaurant_menu_experiments_path(@restaurant, @menu), params: {
          menu_experiment: {
            control_version_id: @v1.id,
            variant_version_id: @v2.id,
            allocation_pct: 0, # invalid
            starts_at: 2.hours.from_now.strftime('%Y-%m-%dT%H:%M'),
            ends_at: 48.hours.from_now.strftime('%Y-%m-%dT%H:%M'),
          },
        }
      end
      assert_response :unprocessable_entity
    end

    test 'POST create redirects unauthenticated' do
      post restaurant_menu_experiments_path(@restaurant, @menu), params: {
        menu_experiment: { control_version_id: @v1.id },
      }
      assert_redirected_to new_user_session_path
    end

    # === Show ===

    test 'GET show succeeds for owner' do
      sign_in @owner
      exp = create_experiment
      get restaurant_menu_experiment_path(@restaurant, @menu, exp)
      assert_response :success
    ensure
      exp&.destroy!
    end

    # === Pause ===

    test 'PATCH pause transitions active experiment to paused' do
      sign_in @owner
      exp = create_experiment(status: :active)
      patch pause_restaurant_menu_experiment_path(@restaurant, @menu, exp)
      exp.reload
      assert exp.status_paused?
    ensure
      exp&.destroy!
    end

    test 'PATCH pause rejects non-active experiment' do
      sign_in @owner
      exp = create_experiment(status: :draft)
      patch pause_restaurant_menu_experiment_path(@restaurant, @menu, exp)
      exp.reload
      assert exp.status_draft?
    ensure
      exp&.destroy!
    end

    # === End ===

    test 'PATCH end_experiment ends active experiment' do
      sign_in @owner
      exp = create_experiment(status: :active)
      patch end_experiment_restaurant_menu_experiment_path(@restaurant, @menu, exp)
      exp.reload
      assert exp.status_ended?
    ensure
      exp&.destroy!
    end

    # === Destroy ===

    test 'DELETE destroy removes draft experiment' do
      sign_in @owner
      exp = create_experiment(status: :draft)
      assert_difference 'MenuExperiment.count', -1 do
        delete restaurant_menu_experiment_path(@restaurant, @menu, exp)
      end
    end

    test 'DELETE destroy rejects non-draft experiment' do
      sign_in @owner
      exp = create_experiment(status: :active)
      assert_no_difference 'MenuExperiment.count' do
        delete restaurant_menu_experiment_path(@restaurant, @menu, exp)
      end
    ensure
      exp&.destroy!
    end

    private

    def create_experiment(status: :draft)
      MenuExperiment.create!(
        menu: @menu,
        control_version: @v1,
        variant_version: @v2,
        allocation_pct: 50,
        starts_at: 1.hour.from_now,
        ends_at: 24.hours.from_now,
        status: status,
      )
    end
  end
end

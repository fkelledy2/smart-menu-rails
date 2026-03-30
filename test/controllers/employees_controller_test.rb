# frozen_string_literal: true

require 'test_helper'

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  # EmployeesController tests.
  # Focuses on: authentication gates, ownership, CRUD actions, reorder, bulk_update.
  #
  # Stubs used:
  #   - AdvancedCacheService  — avoids Memcached dependency
  #   - AnalyticsService      — avoids analytics side-effects

  def setup
    @owner      = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @employee   = employees(:one)

    # Shape returned by AdvancedCacheService HTML-path methods
    @cache_employees_result = {
      employees: [],
      metadata: { restaurants_count: 1, total_employees: 0, active_employees: 0 },
    }
    @cache_employee_result = {
      employee: {},
      metadata: {},
    }
    @cache_analytics_result = {
      performance: {},
      metadata: { period_days: 30 },
    }
    @cache_summary_result = {
      summary: { total_employees: 0, active_employees: 0 },
      metadata: {},
    }
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/employees (index)
  # ---------------------------------------------------------------------------

  test 'GET index redirects unauthenticated' do
    get restaurant_employees_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET index as JSON succeeds for owner' do
    sign_in @owner

    get restaurant_employees_path(@restaurant), as: :json
    assert_response :success
  end

  test 'GET index as JSON without restaurant_id succeeds for owner' do
    sign_in @owner

    get restaurant_employees_path(@restaurant), as: :json
    assert_response :success
  end

  test 'GET index as JSON returns 401 when not signed in' do
    get restaurant_employees_path(@restaurant), as: :json
    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/employees/:id (show)
  # ---------------------------------------------------------------------------

  test 'GET show as JSON succeeds for owner' do
    sign_in @owner

    AnalyticsService.stub(:track_user_event, nil) do
      get restaurant_employee_path(@restaurant, @employee), as: :json
      assert_response :success
    end
  end

  test 'GET show redirects for non-owner (set_employee guard)' do
    sign_in @other_user

    # @employee belongs to restaurants(:one) owned by users(:one).
    # set_employee redirects because restaurant.user != current_user.
    AnalyticsService.stub(:track_user_event, nil) do
      get restaurant_employee_path(@restaurant, @employee)
      assert_redirected_to root_url
    end
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/employees/new
  # ---------------------------------------------------------------------------

  test 'GET new redirects unauthenticated' do
    get new_restaurant_employee_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for owner' do
    sign_in @owner

    get new_restaurant_employee_path(@restaurant)
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/employees/:id/edit
  # ---------------------------------------------------------------------------

  test 'GET edit succeeds for owner' do
    sign_in @owner

    get edit_restaurant_employee_path(@restaurant, @employee)
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/employees (create)
  # ---------------------------------------------------------------------------

  test 'POST create with HTML redirects on success' do
    sign_in @owner

    AnalyticsService.stub(:track_user_event, nil) do
      assert_difference 'Employee.count', 1 do
        post restaurant_employees_path(@restaurant), params: {
          employee: {
            name: 'Jane Doe',
            eid: 'EID-99',
            role: 'staff',
            status: 'active',
            restaurant_id: @restaurant.id,
            user_id: @owner.id,
          },
        }
      end
    end

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'staff')
  end

  test 'POST create with HTML renders new on validation failure' do
    sign_in @owner

    assert_no_difference 'Employee.count' do
      post restaurant_employees_path(@restaurant), params: {
        employee: {
          name: '',
          eid: 'EID-100',
          role: 'staff',
          status: 'active',
          restaurant_id: @restaurant.id,
          user_id: @owner.id,
        },
      }
    end

    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # PATCH /restaurants/:restaurant_id/employees/:id (update)
  # ---------------------------------------------------------------------------

  test 'PATCH update succeeds for owner and redirects' do
    sign_in @owner

    AdvancedCacheService.stub(:invalidate_employee_caches, nil) do
      AdvancedCacheService.stub(:invalidate_restaurant_caches, nil) do
        AdvancedCacheService.stub(:invalidate_user_caches, nil) do
          AnalyticsService.stub(:track_user_event, nil) do
            patch restaurant_employee_path(@restaurant, @employee), params: {
              employee: { name: 'Updated Name' },
            }
          end
        end
      end
    end

    assert_redirected_to edit_restaurant_path(id: @restaurant.id)
    assert_equal 'Updated Name', @employee.reload.name
  end

  test 'PATCH update redirects non-owner' do
    sign_in @other_user

    patch restaurant_employee_path(@restaurant, @employee), as: :json
    # set_employee guard fires for non-owner, redirect to root
    assert_redirected_to root_url
  end

  # ---------------------------------------------------------------------------
  # DELETE /restaurants/:restaurant_id/employees/:id (destroy)
  # ---------------------------------------------------------------------------

  test 'DELETE destroy archives the employee for owner' do
    sign_in @owner

    employee_to_archive = Employee.create!(
      name: 'Temp Staff',
      eid: 'TEMP-1',
      role: 'staff',
      status: 'active',
      restaurant: @restaurant,
      user: @owner,
    )

    AdvancedCacheService.stub(:invalidate_employee_caches, nil) do
      AdvancedCacheService.stub(:invalidate_restaurant_caches, nil) do
        AdvancedCacheService.stub(:invalidate_user_caches, nil) do
          delete restaurant_employee_path(@restaurant, employee_to_archive), as: :json
        end
      end
    end

    assert_response :no_content
    assert employee_to_archive.reload.archived
  end

  test 'DELETE destroy redirects non-owner via set_employee guard' do
    sign_in @other_user

    delete restaurant_employee_path(@restaurant, @employee), as: :json
    assert_redirected_to root_url
  end

  # ---------------------------------------------------------------------------
  # PATCH /restaurants/:restaurant_id/employees/reorder
  # ---------------------------------------------------------------------------

  test 'PATCH reorder returns success JSON for owner' do
    sign_in @owner

    patch reorder_restaurant_employees_path(@restaurant), params: {
      order: [{ id: @employee.id, sequence: 1 }],
    }, as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 'success', body['status']
  end

  test 'PATCH reorder returns error for invalid payload' do
    sign_in @owner

    patch reorder_restaurant_employees_path(@restaurant), params: {
      order: 'not-an-array',
    }, as: :json

    assert_response :unprocessable_entity
  end

  test 'PATCH reorder redirects unauthenticated' do
    patch reorder_restaurant_employees_path(@restaurant), as: :json
    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # PATCH /restaurants/:restaurant_id/employees/bulk_update
  # ---------------------------------------------------------------------------

  test 'PATCH bulk_update with valid ids redirects for owner' do
    sign_in @owner

    patch bulk_update_restaurant_employees_path(@restaurant), params: {
      employee_ids: [@employee.id],
      status: 'active',
    }

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'staff')
  end

  test 'PATCH bulk_update with empty ids redirects for owner' do
    sign_in @owner

    patch bulk_update_restaurant_employees_path(@restaurant), params: {
      employee_ids: [],
      status: 'active',
    }

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'staff')
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/employees/:id/analytics
  # ---------------------------------------------------------------------------

  test 'GET analytics as JSON returns analytics data for owner' do
    sign_in @owner

    analytics_stub = { performance: {}, metadata: { period_days: 30 } }
    AdvancedCacheService.stub(:cached_employee_performance, analytics_stub) do
      AnalyticsService.stub(:track_user_event, nil) do
        get analytics_restaurant_employee_path(@restaurant, @employee), as: :json
      end
    end

    assert_response :success
  end
end

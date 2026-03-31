# frozen_string_literal: true

require 'test_helper'

class OrdrsControllerTest < ActionDispatch::IntegrationTest
  # OrdrsController tests.
  # Focuses on: authentication gates, ownership scoping, create/show/update/destroy
  # for authenticated owners and unauthenticated (guest) users.
  #
  # Stubs used throughout:
  #   - AdvancedCacheServiceV2  — avoids Memcached dependency
  #   - AdvancedCacheService    — avoids Memcached dependency
  #   - AnalyticsService        — avoids analytics side-effects
  #   - ActionCable broadcasts  — avoids WebSocket connection errors
  #   - OrderEvent / OrderEventProjector — avoids AASM transition complexity
  #   - CacheInvalidationJob    — avoids Sidekiq

  def setup
    @owner      = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @ordr       = ordrs(:one)
    @menu       = menus(:one)
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/ordrs (index)
  # ---------------------------------------------------------------------------

  test 'GET index redirects unauthenticated' do
    get restaurant_ordrs_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET index as JSON with restaurant scope succeeds for owner' do
    sign_in @owner

    get restaurant_ordrs_path(@restaurant), as: :json
    assert_response :success
  end

  test 'GET index as JSON returns 401 when not signed in' do
    get restaurant_ordrs_path(@restaurant), as: :json
    assert_response :unauthorized
  end

  test 'GET index as JSON succeeds for owner' do
    sign_in @owner

    get restaurant_ordrs_path(@restaurant), as: :json
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/ordrs/:id (show)
  # ---------------------------------------------------------------------------

  test 'GET show as JSON succeeds for restaurant owner' do
    sign_in @owner

    AnalyticsService.stub(:track_user_event, nil) do
      get restaurant_ordr_path(@restaurant, @ordr), as: :json
      assert_response :success
    end
  end

  test 'GET show as JSON returns ordr data for owner' do
    sign_in @owner

    AnalyticsService.stub(:track_user_event, nil) do
      get restaurant_ordr_path(@restaurant, @ordr), as: :json
      assert_response :success
      body = response.parsed_body
      assert_equal @ordr.id, body['id']
    end
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/ordrs (create)
  # ---------------------------------------------------------------------------

  test 'POST create as JSON creates ordr and returns 201' do
    sign_in @owner

    stub_broadcasts do
      AnalyticsService.stub(:track_user_event, nil) do
        assert_difference '@restaurant.ordrs.count', 1 do
          post restaurant_ordrs_path(@restaurant), params: {
            ordr: {
              menu_id: @menu.id,
              tablesetting_id: tablesettings(:one).id,
              ordercapacity: 2,
            },
          }, as: :json
        end
      end
    end

    assert_response :created
  end

  test 'POST create without required params returns unprocessable_content' do
    sign_in @owner

    # Omitting menu_id and tablesetting_id causes save failure (NOT NULL constraints).
    assert_no_difference '@restaurant.ordrs.count' do
      post restaurant_ordrs_path(@restaurant), params: {
        ordr: { menu_id: nil, tablesetting_id: nil },
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # PATCH /restaurants/:restaurant_id/ordrs/:id (update)
  # ---------------------------------------------------------------------------

  test 'PATCH update succeeds for restaurant owner' do
    sign_in @owner

    stub_broadcasts do
      OrderEvent.stub(:emit!, nil) do
        OrderEventProjector.stub(:project!, nil) do
          CacheInvalidationJob.stub(:perform_later, nil) do
            patch restaurant_ordr_path(@restaurant, @ordr), params: {
              ordr: { ordercapacity: 3 },
            }, as: :json
          end
        end
      end
    end

    assert_response :ok
    assert_equal 3, @ordr.reload.ordercapacity
  end

  test 'PATCH update status transition is recorded as an event' do
    sign_in @owner

    event_emitted = false
    stub_broadcasts do
      OrderEvent.stub(:emit!, ->(**_kwargs) { event_emitted = true }) do
        OrderEventProjector.stub(:project!, nil) do
          CacheInvalidationJob.stub(:perform_later, nil) do
            patch restaurant_ordr_path(@restaurant, @ordr), params: {
              ordr: { status: 20 }, # ordered
            }, as: :json
          end
        end
      end
    end

    assert_response :ok
    assert event_emitted, 'OrderEvent.emit! should have been called for status change'
  end

  # ---------------------------------------------------------------------------
  # DELETE /restaurants/:restaurant_id/ordrs/:id (destroy)
  # ---------------------------------------------------------------------------

  test 'DELETE destroy removes the ordr for owner' do
    sign_in @owner

    ordr_to_delete = @restaurant.ordrs.create!(
      menu: @menu,
      tablesetting: tablesettings(:one),
      status: 0,
      ordercapacity: 1,
      nett: 0, tip: 0, service: 0, tax: 0, gross: 0,
    )

    CacheInvalidationJob.stub(:perform_later, nil) do
      assert_difference '@restaurant.ordrs.count', -1 do
        delete restaurant_ordr_path(@restaurant, ordr_to_delete)
      end
    end

    assert_redirected_to restaurant_ordrs_url(@restaurant)
  end

  test 'DELETE destroy denies access for non-owner and returns 403' do
    sign_in @other_user

    # @ordr belongs to restaurant :one (owned by users(:one)); @other_user owns restaurant :two.
    # ApplicationController rescues Pundit::NotAuthorizedError and renders a 403/redirect.
    assert_no_difference '@restaurant.ordrs.count' do
      delete restaurant_ordr_path(@restaurant, @ordr), as: :json
    end

    assert_response :forbidden
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/ordrs/:id/events
  # ---------------------------------------------------------------------------

  test 'GET events returns JSON with order events' do
    sign_in @owner

    get events_restaurant_ordr_path(@restaurant, @ordr), as: :json
    assert_response :success

    body = response.parsed_body
    assert body.key?('order_id')
    assert body.key?('events')
  end

  private

  def stub_cache_services(&block)
    empty_result = { orders: [], cached_calculations: {}, metadata: { restaurants_count: 0 } }
    AdvancedCacheServiceV2.stub(:cached_restaurant_orders_with_models, empty_result) do
      AdvancedCacheServiceV2.stub(:cached_user_all_orders_with_models, empty_result) do
        AdvancedCacheService.stub(:cached_order_with_details, {
          calculations: { nett: 0, tax: 0, service: 0, covercharge: 0, gross: 0 },
        }) do
          block.call
        end
      end
    end
  end

  def stub_broadcasts(&block)
    ActionCable.server.stub(:broadcast, nil) do
      block.call
    end
  end
end

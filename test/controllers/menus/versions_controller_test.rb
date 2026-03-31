# frozen_string_literal: true

require 'test_helper'

class Menus::VersionsControllerTest < ActionDispatch::IntegrationTest
  # Menus::VersionsController tests.
  # Focuses on: authentication, authorization, versions list, diff, create_version, activate_version.
  #
  # MenuVersion records are created dynamically — no fixture file exists.
  # MenuVersionSnapshotService is stubbed for create_version to avoid deep menu traversal.

  def setup
    @owner      = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @menu       = menus(:one) # belongs to restaurant :one (owner = users :one)

    # Stub snapshot so MenuVersion.create_from_menu! doesn't require full menu data
    @snapshot_stub = { sections: [] }.to_json

    # Fixtures bypass after_commit; ensure the restaurant_menus join record exists so
    # set_menu can find the menu via the join.
    RestaurantMenu.find_or_create_by!(restaurant_id: @restaurant.id, menu_id: @menu.id) do |rm|
      rm.sequence = 1
      rm.status = :active
      rm.availability_state = :available
    end
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/menus/:id/versions
  # ---------------------------------------------------------------------------

  test 'GET versions redirects unauthenticated' do
    get versions_restaurant_menu_path(@restaurant, @menu)
    assert_redirected_to new_user_session_path
  end

  test 'GET versions returns JSON with version list for owner' do
    sign_in @owner

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      v = MenuVersion.create_from_menu!(menu: @menu, user: @owner)

      get versions_restaurant_menu_path(@restaurant, @menu), as: :json
      assert_response :success

      body = response.parsed_body
      assert_equal @menu.id, body['menu_id']
      assert body.key?('versions')
      assert body.key?('count')

      v.destroy!
    end
  end

  test 'GET versions with no versions returns empty list' do
    sign_in @owner

    # Ensure no versions exist for this menu
    @menu.menu_versions.destroy_all

    get versions_restaurant_menu_path(@restaurant, @menu), as: :json
    assert_response :success

    body = response.parsed_body
    assert_equal 0, body['count']
    assert_empty body['versions']
  end

  test 'GET versions returns 403 for non-owner' do
    sign_in @other_user

    # @menu belongs to restaurant :one (owned by users :one), not @other_user
    get versions_restaurant_menu_path(@restaurant, @menu), as: :json
    assert_response :forbidden
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/menus/:id/versions/:from/diff/:to
  # ---------------------------------------------------------------------------

  test 'GET version_diff returns diff JSON for owner' do
    sign_in @owner

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      v1 = MenuVersion.create_from_menu!(menu: @menu, user: @owner)
      v2 = MenuVersion.create_from_menu!(menu: @menu, user: @owner)

      get version_diff_restaurant_menu_path(@restaurant, @menu, from_version_id: v1.id, to_version_id: v2.id),
          as: :json
      assert_response :success

      body = response.parsed_body
      assert_equal @menu.id, body['menu_id']
      assert body.key?('diff')

      v1.destroy!
      v2.destroy!
    end
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/menus/:id/versions/diff (versions_diff)
  # ---------------------------------------------------------------------------

  test 'GET versions_diff returns diff JSON for owner' do
    sign_in @owner

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      v1 = MenuVersion.create_from_menu!(menu: @menu, user: @owner)
      v2 = MenuVersion.create_from_menu!(menu: @menu, user: @owner)

      get versions_diff_restaurant_menu_path(@restaurant, @menu,
                                             from_version_id: v1.id,
                                             to_version_id: v2.id,), as: :json
      assert_response :success

      body = response.parsed_body
      assert_equal @menu.id, body['menu_id']
      assert body.key?('diff')

      v1.destroy!
      v2.destroy!
    end
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/menus/:id/create_version
  # ---------------------------------------------------------------------------

  test 'POST create_version as JSON creates a new menu version' do
    sign_in @owner

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      assert_difference '@menu.menu_versions.count', 1 do
        post create_version_restaurant_menu_path(@restaurant, @menu), as: :json
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal @menu.id, body['menu_id']
    assert body.dig('menu_version', 'id')
  end

  test 'POST create_version redirects unauthenticated' do
    post create_version_restaurant_menu_path(@restaurant, @menu)
    assert_redirected_to new_user_session_path
  end

  test 'POST create_version denied for non-owner' do
    sign_in @other_user

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      assert_no_difference '@menu.menu_versions.count' do
        post create_version_restaurant_menu_path(@restaurant, @menu), as: :json
      end
    end

    assert_response :forbidden
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/menus/:id/activate_version
  # ---------------------------------------------------------------------------

  test 'POST activate_version as JSON activates a version for owner' do
    sign_in @owner

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      version = MenuVersion.create_from_menu!(menu: @menu, user: @owner)

      post activate_version_restaurant_menu_path(@restaurant, @menu), params: {
        menu_version_id: version.id,
        starts_at: Time.current.iso8601,
      }, as: :json

      assert_response :success
      body = response.parsed_body
      assert_equal @menu.id, body['menu_id']
      assert body['activated_menu_version_id']

      version.destroy!
    end
  end

  test 'POST activate_version denied for non-owner' do
    sign_in @other_user

    MenuVersionSnapshotService.stub(:snapshot_for, @snapshot_stub) do
      version = MenuVersion.create_from_menu!(menu: menus(:one), user: @owner)

      post activate_version_restaurant_menu_path(@restaurant, @menu), params: {
        menu_version_id: version.id,
      }, as: :json

      assert_response :forbidden
      version.destroy!
    end
  end
end

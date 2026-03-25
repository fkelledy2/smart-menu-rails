# frozen_string_literal: true

require 'test_helper'

module MarketingQrCodes
  class LinkServiceTest < ActiveSupport::TestCase
    setup do
      @admin      = users(:super_admin)
      @restaurant = restaurants(:one)
      @menu       = menus(:one)
      # Use table_one which matches smartmenus(:one) fixture (restaurant:one, menu:one, tablesetting:table_one)
      @table      = tablesettings(:table_one)
      @qr         = marketing_qr_codes(:unlinked_qr)
    end

    # -------------------------------------------------------------------------
    # Happy paths
    # -------------------------------------------------------------------------

    test 'links to restaurant only (no menu or table)' do
      # Create a QR with no prior restaurant link
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)

      result = LinkService.call(marketing_qr_code: qr, restaurant: @restaurant)

      assert result.success?, result.error
      qr.reload
      assert qr.linked?
      assert_equal @restaurant, qr.restaurant
      assert_nil qr.menu
      assert_nil qr.tablesetting
      assert_not_nil qr.smartmenu
      assert_equal @restaurant.id, qr.smartmenu.restaurant_id
    end

    test 'links to restaurant and menu' do
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)

      result = LinkService.call(marketing_qr_code: qr, restaurant: @restaurant, menu: @menu)

      assert result.success?, result.error
      qr.reload
      assert_equal @menu, qr.menu
      assert_nil qr.tablesetting
    end

    test 'links to restaurant, menu, and tablesetting' do
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)

      result = LinkService.call(
        marketing_qr_code: qr,
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: @table,
      )

      assert result.success?, result.error
      qr.reload
      assert_equal @restaurant, qr.restaurant
      assert_equal @menu, qr.menu
      assert_equal @table, qr.tablesetting
      assert_not_nil qr.smartmenu
    end

    # -------------------------------------------------------------------------
    # Idempotency — reuses existing Smartmenu
    # -------------------------------------------------------------------------

    test 'reuses existing smartmenu when linking same restaurant+menu+table' do
      # smartmenus(:one) = restaurant:one + menu:ordering_menu + tablesetting:table_one
      existing_sm = smartmenus(:one)
      ordering_menu = menus(:ordering_menu)
      table_one     = tablesettings(:table_one)
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)

      result = LinkService.call(
        marketing_qr_code: qr,
        restaurant: @restaurant,
        menu: ordering_menu,
        tablesetting: table_one,
      )

      assert result.success?, result.error
      assert_equal existing_sm.id, qr.reload.smartmenu_id
    end

    test 'idempotent on second call — does not create duplicate smartmenu' do
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)

      Smartmenu.count
      LinkService.call(marketing_qr_code: qr, restaurant: @restaurant, menu: @menu, tablesetting: @table)
      after_count = Smartmenu.count

      # Second call with the same combination should reuse the existing smartmenu
      qr2 = MarketingQrCode.create!(created_by_user_id: @admin.id)
      LinkService.call(marketing_qr_code: qr2, restaurant: @restaurant, menu: @menu, tablesetting: @table)

      assert_equal after_count, Smartmenu.count
    end

    # -------------------------------------------------------------------------
    # Error paths
    # -------------------------------------------------------------------------

    test 'fails without restaurant' do
      result = LinkService.call(marketing_qr_code: @qr, restaurant: nil)

      assert_not result.success?
      assert_equal 'Restaurant is required', result.error
    end

    test 'fails with nil marketing_qr_code' do
      result = LinkService.call(marketing_qr_code: nil, restaurant: @restaurant)

      assert_not result.success?
      assert_equal 'Marketing QR code not found', result.error
    end

    # -------------------------------------------------------------------------
    # Slug generation
    # -------------------------------------------------------------------------

    test 'creates a slug-safe smartmenu slug from restaurant name' do
      restaurant = Restaurant.create!(
        name: 'Le Café & Bistro',
        user: @admin,
        currency: 'EUR',
        status: 1,
      )
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)

      result = LinkService.call(marketing_qr_code: qr, restaurant: restaurant)

      assert result.success?, result.error
      slug = qr.reload.smartmenu.slug
      assert_match(/\A[a-z0-9-]+\z/, slug)
    end

    test 'generates unique slug when global collision exists' do
      # Create a smartmenu on a different restaurant that will collide slug-wise.
      # The service checks global slug uniqueness before creating.
      other_restaurant = restaurants(:two)
      Smartmenu.where(restaurant: other_restaurant).delete_all
      Smartmenu.create!(
        restaurant: other_restaurant,
        slug: 'slug-test',
        public_token: SecureRandom.hex(32),
      )

      restaurant = Restaurant.create!(name: 'Slug Test', user: @admin, currency: 'EUR', status: 1)
      qr = MarketingQrCode.create!(created_by_user_id: @admin.id)
      result = LinkService.call(marketing_qr_code: qr, restaurant: restaurant)

      assert result.success?, result.error
      slug = qr.reload.smartmenu.slug
      assert_not_equal 'slug-test', slug
      assert slug.start_with?('slug-test-'), "Expected slug to start with 'slug-test-' but was: #{slug.inspect}"
    end
  end
end

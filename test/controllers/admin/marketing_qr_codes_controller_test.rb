# frozen_string_literal: true

require 'test_helper'

class Admin::MarketingQrCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mellow_admin = users(:super_admin)  # email: admin@mellow.menu
    @regular_user = users(:one)          # email: test1@gmail.com
  end

  # ---------------------------------------------------------------------------
  # Access control — non-mellow.menu users must be rejected
  # ---------------------------------------------------------------------------

  test 'non-mellow user cannot access index (redirect)' do
    sign_in @regular_user
    get admin_marketing_qr_codes_path
    assert_redirected_to root_path
  end

  test 'unauthenticated user cannot access index' do
    get admin_marketing_qr_codes_path
    # Devise redirects to sign_in
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'mellow admin can access index' do
    sign_in @mellow_admin
    get admin_marketing_qr_codes_path
    assert_response :ok
  end

  test 'index lists QR codes' do
    sign_in @mellow_admin
    get admin_marketing_qr_codes_path
    assert_select 'table'
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'mellow admin can load new form' do
    sign_in @mellow_admin
    get new_admin_marketing_qr_code_path
    assert_response :ok
  end

  test 'create generates a new QR code with token' do
    sign_in @mellow_admin

    assert_difference 'MarketingQrCode.count', 1 do
      post admin_marketing_qr_codes_path, params: {
        marketing_qr_code: { name: 'Test QR', campaign: 'launch-2026' },
      }
    end

    qr = MarketingQrCode.last
    assert_redirected_to admin_marketing_qr_code_path(qr)
    assert_equal 'Test QR', qr.name
    assert qr.token.present?
    assert_equal @mellow_admin.id, qr.created_by_user_id
    assert qr.unlinked?
  end

  test 'create sets created_by_user_id from current_user' do
    sign_in @mellow_admin
    post admin_marketing_qr_codes_path, params: {
      marketing_qr_code: { name: 'Auth Test' },
    }
    assert_equal @mellow_admin.id, MarketingQrCode.last.created_by_user_id
  end

  # ---------------------------------------------------------------------------
  # Show
  # ---------------------------------------------------------------------------

  test 'mellow admin can view a QR code' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    get admin_marketing_qr_code_path(qr)
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # Edit / Update
  # ---------------------------------------------------------------------------

  test 'mellow admin can update name and campaign' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    patch admin_marketing_qr_code_path(qr), params: {
      marketing_qr_code: { name: 'Updated Name', campaign: 'new-campaign' },
    }
    assert_redirected_to admin_marketing_qr_code_path(qr)
    qr.reload
    assert_equal 'Updated Name', qr.name
    assert_equal 'new-campaign', qr.campaign
  end

  test 'update cannot change token' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    original_token = qr.token
    patch admin_marketing_qr_code_path(qr), params: {
      marketing_qr_code: { name: 'Hack', token: 'hacked-token' },
    }
    assert_equal original_token, qr.reload.token
  end

  # ---------------------------------------------------------------------------
  # Destroy (archive)
  # ---------------------------------------------------------------------------

  test 'destroy archives the QR code' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    delete admin_marketing_qr_code_path(qr)
    assert_redirected_to admin_marketing_qr_codes_path
    assert qr.reload.archived?
  end

  # ---------------------------------------------------------------------------
  # Link
  # ---------------------------------------------------------------------------

  test 'link action links QR code to a restaurant' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    restaurant = restaurants(:two)

    patch link_admin_marketing_qr_code_path(qr), params: {
      restaurant_id: restaurant.id,
    }

    assert_redirected_to admin_marketing_qr_code_path(qr)
    qr.reload
    assert qr.linked?
    assert_equal restaurant.id, qr.restaurant_id
  end

  test 'link with invalid restaurant redirects with alert' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    patch link_admin_marketing_qr_code_path(qr), params: { restaurant_id: 99_999_999 }
    assert_redirected_to admin_marketing_qr_code_path(qr)
    assert_match(/Restaurant not found/, flash[:alert])
  end

  # ---------------------------------------------------------------------------
  # Unlink
  # ---------------------------------------------------------------------------

  test 'unlink reverts a linked QR to unlinked' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:linked_qr)
    patch unlink_admin_marketing_qr_code_path(qr)

    assert_redirected_to admin_marketing_qr_code_path(qr)
    qr.reload
    assert qr.unlinked?
    assert_nil qr.restaurant_id
    assert_nil qr.menu_id
    assert_nil qr.tablesetting_id
    assert_nil qr.smartmenu_id
  end

  # ---------------------------------------------------------------------------
  # Print
  # ---------------------------------------------------------------------------

  test 'print returns 200 with no layout' do
    sign_in @mellow_admin
    qr = marketing_qr_codes(:unlinked_qr)
    get print_admin_marketing_qr_code_path(qr)
    assert_response :ok
    # Print view is layout-free HTML — should contain the token
    assert_match qr.token, response.body
  end
end

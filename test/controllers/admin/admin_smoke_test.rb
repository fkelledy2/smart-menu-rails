# frozen_string_literal: true

# Smoke test: every admin index/list page should return 200 when visited by a super admin.
# Run with: bin/fast_test test/controllers/admin/admin_smoke_test.rb

require 'test_helper'

class Admin::AdminSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:super_admin)
    sign_in @user
    Flipper.enable(:crm_sales_funnel, @user)
  end

  teardown do
    Flipper.disable(:crm_sales_funnel)
  end

  # ---------------------------------------------------------------------------
  # Operations
  # ---------------------------------------------------------------------------

  test 'feature flags index renders' do
    get admin_feature_flags_path
    assert_response :success
  end

  test 'impersonation new renders' do
    get new_admin_impersonation_path
    assert_response :success
  end

  test 'jwt tokens index renders' do
    get admin_jwt_tokens_path
    assert_response :success
  end

  test 'jwt tokens new renders' do
    get new_admin_jwt_token_path
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # Discovery
  # ---------------------------------------------------------------------------

  test 'city crawl new renders' do
    get new_admin_city_crawl_path
    assert_response :success
  end

  test 'discovered restaurants index renders' do
    get admin_discovered_restaurants_path
    assert_response :success
  end

  test 'discovered restaurants approved imports renders' do
    get approved_imports_admin_discovered_restaurants_path
    assert_response :success
  end

  test 'menu source change reviews index renders' do
    get admin_menu_source_change_reviews_path
    assert_response :success
  end

  test 'crawl source rules index renders' do
    get admin_crawl_source_rules_path
    assert_response :success
  end

  test 'crawl source rules new renders' do
    get new_admin_crawl_source_rule_path
    assert_response :success
  end

  test 'local guides index renders' do
    get admin_local_guides_path
    assert_response :success
  end

  test 'local guides new renders' do
    get new_admin_local_guide_path
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # Sales & CRM
  # ---------------------------------------------------------------------------

  test 'crm leads index renders' do
    get admin_crm_leads_path
    assert_response :success
  end

  test 'crm leads new renders' do
    get new_admin_crm_lead_path
    assert_response :success
  end

  test 'demo bookings index renders' do
    get admin_demo_bookings_path
    assert_response :success
  end

  test 'marketing qr codes index renders' do
    get admin_marketing_qr_codes_path
    assert_response :success
  end

  test 'marketing qr codes new renders' do
    get new_admin_marketing_qr_code_path
    assert_response :success
  end

  test 'restaurant claim requests index renders' do
    get admin_restaurant_claim_requests_path
    assert_response :success
  end

  test 'restaurant removal requests index renders' do
    get admin_restaurant_removal_requests_path
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # Finance
  # ---------------------------------------------------------------------------

  test 'cost insights index renders' do
    get admin_cost_insights_path
    assert_response :success
  end

  test 'pricing models index renders' do
    get admin_pricing_models_path
    assert_response :success
  end

  test 'pricing models new renders' do
    get new_admin_pricing_model_path
    assert_response :success
  end

  test 'margin policies index renders' do
    get admin_margin_policies_path
    assert_response :success
  end

  test 'margin policies new renders' do
    get new_admin_margin_policy_path
    assert_response :success
  end

  test 'vendor costs index renders' do
    get admin_vendor_costs_path
    assert_response :success
  end

  test 'vendor costs new renders' do
    get new_admin_vendor_cost_path
    assert_response :success
  end

  test 'staff costs index renders' do
    get admin_staff_costs_path
    assert_response :success
  end

  test 'staff costs new renders' do
    get new_admin_staff_cost_path
    assert_response :success
  end

  test 'heroku inventories index renders' do
    get admin_heroku_inventories_path
    assert_response :success
  end

  test 'heroku inventories coefficients renders' do
    get coefficients_admin_heroku_inventories_path
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # System
  # ---------------------------------------------------------------------------

  test 'metrics index renders' do
    get admin_metrics_path
    assert_response :success
  end

  test 'performance index renders' do
    get admin_performance_index_path
    assert_response :success
  end

  test 'cache index renders' do
    get admin_cache_index_path
    assert_response :success
  end
end

# frozen_string_literal: true

require 'test_helper'

class Admin::PricingModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin   = users(:super_admin)
    @plain_admin   = users(:admin)
    @regular_user  = users(:one)
    @draft_model   = pricing_models(:draft_2026_q2)
    @published_model = pricing_models(:legacy_v0)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user cannot access index' do
    get admin_pricing_models_path
    assert_response :redirect
  end

  test 'plain admin cannot access pricing models' do
    sign_in @plain_admin
    get admin_pricing_models_path
    assert_redirected_to root_path
  end

  test 'regular user cannot access pricing models' do
    sign_in @regular_user
    get admin_pricing_models_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index
  # ---------------------------------------------------------------------------

  test 'super admin can list pricing models' do
    sign_in @super_admin
    get admin_pricing_models_path
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # Show
  # ---------------------------------------------------------------------------

  test 'super admin can view a pricing model' do
    sign_in @super_admin
    get admin_pricing_model_path(@draft_model)
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'super admin can load new form' do
    sign_in @super_admin
    get new_admin_pricing_model_path
    assert_response :ok
  end

  test 'super admin can create a draft pricing model' do
    sign_in @super_admin
    assert_difference('PricingModel.count', 1) do
      post admin_pricing_models_path, params: {
        pricing_model: {
          version: "test_#{SecureRandom.hex(4)}",
          currency: 'EUR',
          inputs_total_cost_cents: 500_000,
          inputs_target_gross_margin_pct: 60,
        },
      }
    end
    assert_redirected_to admin_pricing_model_path(PricingModel.last)
  end

  test 'invalid create renders new form' do
    sign_in @super_admin
    assert_no_difference('PricingModel.count') do
      post admin_pricing_models_path, params: {
        pricing_model: { version: '', currency: 'INVALID' },
      }
    end
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # Edit / Update — draft model
  # ---------------------------------------------------------------------------

  test 'super admin can load edit form for draft model' do
    sign_in @super_admin
    get edit_admin_pricing_model_path(@draft_model)
    assert_response :ok
  end

  test 'super admin can update a draft model' do
    sign_in @super_admin
    patch admin_pricing_model_path(@draft_model), params: {
      pricing_model: {
        version: @draft_model.version,
        currency: @draft_model.currency,
        inputs_total_cost_cents: 600_000,
        inputs_target_gross_margin_pct: 55,
      },
    }
    assert_redirected_to admin_pricing_model_path(@draft_model)
  end

  test 'editing a published model redirects with alert' do
    sign_in @super_admin
    get edit_admin_pricing_model_path(@published_model)
    assert_redirected_to admin_pricing_model_path(@published_model)
  end

  test 'updating a published model redirects with alert' do
    sign_in @super_admin
    patch admin_pricing_model_path(@published_model), params: {
      pricing_model: { currency: 'USD' },
    }
    assert_redirected_to admin_pricing_model_path(@published_model)
  end

  # ---------------------------------------------------------------------------
  # Preview
  # ---------------------------------------------------------------------------

  test 'super admin can preview a draft model' do
    sign_in @super_admin
    get preview_admin_pricing_model_path(@draft_model)
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test 'super admin can delete a draft model' do
    sign_in @super_admin
    model = PricingModel.create!(
      version: "deletable_#{SecureRandom.hex(4)}",
      currency: 'EUR',
      status: :draft,
    )
    assert_difference('PricingModel.count', -1) do
      delete admin_pricing_model_path(model)
    end
    assert_redirected_to admin_pricing_models_path
  end

  test 'cannot delete a published model' do
    sign_in @super_admin
    assert_no_difference('PricingModel.count') do
      delete admin_pricing_model_path(@published_model)
    end
    assert_redirected_to admin_pricing_models_path
  end
end

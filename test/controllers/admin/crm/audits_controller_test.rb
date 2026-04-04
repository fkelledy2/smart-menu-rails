# frozen_string_literal: true

require 'test_helper'

class Admin::Crm::AuditsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mellow_admin = users(:super_admin)
    @plain_admin  = users(:admin)
    @lead         = crm_leads(:new_lead)

    Flipper.enable(:crm_sales_funnel, @mellow_admin)
  end

  teardown do
    Flipper.disable(:crm_sales_funnel)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user cannot access audits index' do
    get admin_crm_lead_audits_path(@lead)
    assert_response :redirect
  end

  test 'non-mellow admin cannot access audits index' do
    sign_in @plain_admin
    get admin_crm_lead_audits_path(@lead)
    assert_redirected_to root_path
  end

  test 'mellow admin can access audits index' do
    sign_in @mellow_admin
    get admin_crm_lead_audits_path(@lead)
    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # Index — content
  # ---------------------------------------------------------------------------

  test 'audits index returns audit records for the lead' do
    sign_in @mellow_admin
    get admin_crm_lead_audits_path(@lead)
    assert_not_nil assigns(:audits)
  end

  test 'audits are ordered newest first' do
    sign_in @mellow_admin

    Crm::LeadAuditWriter.write(crm_lead: @lead, event: 'lead_created', actor: @mellow_admin)
    travel 1.second do
      Crm::LeadAuditWriter.write(crm_lead: @lead, event: 'field_updated', actor: @mellow_admin,
                                 field_name: 'stage', from_value: 'new', to_value: 'contacted',)
    end

    get admin_crm_lead_audits_path(@lead)
    audits = assigns(:audits)
    assert audits.first.created_at >= audits.last.created_at
  end

  # ---------------------------------------------------------------------------
  # 404 on unknown lead (regression for Bug 1: missing return after head :not_found)
  # ---------------------------------------------------------------------------

  test 'returns 404 for unknown lead_id' do
    sign_in @mellow_admin
    get admin_crm_lead_audits_path(lead_id: 0)
    assert_response :not_found
  end
end

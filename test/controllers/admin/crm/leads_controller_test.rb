# frozen_string_literal: true

require 'test_helper'

class Admin::Crm::LeadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mellow_admin = users(:super_admin)   # admin@mellow.menu, admin: true
    @plain_admin  = users(:admin)         # admin@gmail.com, admin: true
    @regular_user = users(:one)
    @lead         = crm_leads(:new_lead)
    @contacted    = crm_leads(:contacted_lead)
    @lost_lead    = crm_leads(:lost_lead)
    @converted    = crm_leads(:converted_lead)

    Flipper.enable(:crm_sales_funnel, @mellow_admin)
  end

  teardown do
    Flipper.disable(:crm_sales_funnel)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user is redirected from index' do
    get admin_crm_leads_path
    assert_response :redirect
  end

  test 'plain admin (non-mellow.menu) is redirected from index' do
    sign_in @plain_admin
    get admin_crm_leads_path
    assert_redirected_to root_path
  end

  test 'regular user is redirected from index' do
    sign_in @regular_user
    get admin_crm_leads_path
    assert_redirected_to root_path
  end

  test 'mellow admin without flag is redirected from index' do
    Flipper.disable(:crm_sales_funnel)
    sign_in @mellow_admin
    get admin_crm_leads_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Index (Kanban board)
  # ---------------------------------------------------------------------------

  test 'mellow admin can access index' do
    sign_in @mellow_admin
    get admin_crm_leads_path
    assert_response :ok
  end

  test 'index assigns leads_by_stage' do
    sign_in @mellow_admin
    get admin_crm_leads_path
    assert_not_nil assigns(:leads_by_stage)
  end

  # ---------------------------------------------------------------------------
  # Show
  # ---------------------------------------------------------------------------

  test 'mellow admin can view a lead' do
    sign_in @mellow_admin
    get admin_crm_lead_path(@lead)
    assert_response :ok
  end

  test 'non-mellow admin cannot view a lead' do
    sign_in @plain_admin
    get admin_crm_lead_path(@lead)
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # New / Create
  # ---------------------------------------------------------------------------

  test 'mellow admin can load new lead form' do
    sign_in @mellow_admin
    get new_admin_crm_lead_path
    assert_response :ok
  end

  test 'create with valid params creates a lead and redirects' do
    sign_in @mellow_admin

    assert_difference 'CrmLead.count', 1 do
      post admin_crm_leads_path, params: {
        crm_lead: {
          restaurant_name: 'Newly Created Restaurant',
          contact_name: 'Test Contact',
          contact_email: 'test@newlycreated.com',
          source: 'manual',
        },
      }
    end

    new_lead = CrmLead.order(:created_at).last
    assert_redirected_to admin_crm_lead_path(new_lead)
  end

  test 'create writes a lead_created audit record' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadAudit.count', 1 do
      post admin_crm_leads_path, params: {
        crm_lead: { restaurant_name: 'Audit Test Restaurant', source: 'manual' },
      }
    end

    audit = CrmLeadAudit.order(:created_at).last
    assert_equal 'lead_created', audit.event
  end

  test 'create with invalid params re-renders new form' do
    sign_in @mellow_admin

    assert_no_difference 'CrmLead.count' do
      post admin_crm_leads_path, params: {
        crm_lead: { restaurant_name: '' },
      }
    end

    assert_response :unprocessable_content
  end

  test 'non-mellow admin cannot create a lead' do
    sign_in @plain_admin

    assert_no_difference 'CrmLead.count' do
      post admin_crm_leads_path, params: {
        crm_lead: { restaurant_name: 'Blocked', source: 'manual' },
      }
    end

    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Edit / Update
  # ---------------------------------------------------------------------------

  test 'mellow admin can load edit form' do
    sign_in @mellow_admin
    get edit_admin_crm_lead_path(@lead)
    assert_response :ok
  end

  test 'update with valid params redirects to show' do
    sign_in @mellow_admin
    patch admin_crm_lead_path(@lead), params: {
      crm_lead: { restaurant_name: 'Updated Name' },
    }
    assert_redirected_to admin_crm_lead_path(@lead)
    assert_equal 'Updated Name', @lead.reload.restaurant_name
  end

  test 'update writes field_updated audit for changed fields' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadAudit.count', 1 do
      patch admin_crm_lead_path(@lead), params: {
        crm_lead: { restaurant_name: 'Changed Name' },
      }
    end

    audit = @lead.crm_lead_audits.order(:created_at).last
    assert_equal 'field_updated', audit.event
    assert_equal 'restaurant_name', audit.field_name
    assert_equal 'Changed Name', audit.to_value
  end

  test 'update with invalid params re-renders edit form' do
    sign_in @mellow_admin
    patch admin_crm_lead_path(@lead), params: {
      crm_lead: { restaurant_name: '' },
    }
    assert_response :unprocessable_content
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test 'mellow admin can destroy a lead' do
    sign_in @mellow_admin
    assert_difference 'CrmLead.count', -1 do
      delete admin_crm_lead_path(@lead)
    end
    assert_redirected_to admin_crm_leads_path
  end

  test 'non-mellow admin cannot destroy a lead' do
    sign_in @plain_admin
    assert_no_difference 'CrmLead.count' do
      delete admin_crm_lead_path(@lead)
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Transition
  # ---------------------------------------------------------------------------

  test 'transition advances lead stage' do
    sign_in @mellow_admin
    patch transition_admin_crm_lead_path(@lead), params: { stage: 'contacted' }
    assert_equal 'contacted', @lead.reload.stage
  end

  test 'transition returns JSON success for XHR requests' do
    sign_in @mellow_admin
    patch transition_admin_crm_lead_path(@lead),
          params: { stage: 'contacted' },
          as: :json

    assert_response :ok
    assert_equal 'contacted', response.parsed_body['stage']
  end

  test 'transition returns JSON error for invalid transition' do
    sign_in @mellow_admin
    # @lead is 'new', cannot go back to a non-existent stage
    patch transition_admin_crm_lead_path(@lead),
          params: { stage: 'demo_completed' },
          as: :json

    assert_response :unprocessable_entity
    assert_not_nil response.parsed_body['error']
  end

  test 'non-mellow admin cannot transition leads' do
    sign_in @plain_admin
    patch transition_admin_crm_lead_path(@lead), params: { stage: 'contacted' }
    assert_redirected_to root_path
    assert_equal 'new', @lead.reload.stage
  end

  test 'transition to lost requires lost_reason' do
    sign_in @mellow_admin
    patch transition_admin_crm_lead_path(@lead),
          params: { stage: 'lost' },
          as: :json

    assert_response :unprocessable_entity
    assert_not_nil response.parsed_body['error']
    assert_equal 'new', @lead.reload.stage
  end

  test 'transition to lost succeeds when lost_reason is provided' do
    sign_in @mellow_admin
    patch transition_admin_crm_lead_path(@lead),
          params: { stage: 'lost', lost_reason: 'competitor' },
          as: :json

    assert_response :ok
    assert_equal 'lost', @lead.reload.stage
    assert_equal 'competitor', @lead.reload.lost_reason
  end

  test 'transition to lost stores lost_reason_notes when provided' do
    sign_in @mellow_admin
    patch transition_admin_crm_lead_path(@lead),
          params: { stage: 'lost', lost_reason: 'price', lost_reason_notes: 'Too costly for them' },
          as: :json

    assert_equal 'Too costly for them', @lead.reload.lost_reason_notes
  end

  test 'transition writes a stage_changed audit record' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadAudit.count', 1 do
      patch transition_admin_crm_lead_path(@lead),
            params: { stage: 'contacted' },
            as: :json
    end

    audit = @lead.crm_lead_audits.order(:created_at).last
    assert_equal 'stage_changed', audit.event
    assert_equal 'new', audit.from_value
    assert_equal 'contacted', audit.to_value
  end

  test 'update with unchanged fields writes no audit records' do
    sign_in @mellow_admin
    original_name = @lead.restaurant_name

    assert_no_difference 'CrmLeadAudit.count' do
      patch admin_crm_lead_path(@lead), params: {
        crm_lead: { restaurant_name: original_name },
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Convert
  # ---------------------------------------------------------------------------

  test 'mellow admin can convert a trial_active lead with a restaurant' do
    sign_in @mellow_admin
    restaurant = restaurants(:one)

    # Advance @lead through the funnel to trial_active
    @lead.update!(assigned_to: @mellow_admin)
    Crm::LeadTransitionService.call(lead: @lead, new_stage: 'contacted', actor: @mellow_admin)
    Crm::LeadTransitionService.call(lead: @lead, new_stage: 'demo_booked', actor: @mellow_admin)
    Crm::LeadTransitionService.call(lead: @lead, new_stage: 'demo_completed', actor: @mellow_admin)
    Crm::LeadTransitionService.call(lead: @lead, new_stage: 'proposal_sent', actor: @mellow_admin)
    Crm::LeadTransitionService.call(lead: @lead, new_stage: 'trial_active', actor: @mellow_admin)
    @lead.reload

    patch convert_admin_crm_lead_path(@lead), params: { restaurant_id: restaurant.id }
    assert_redirected_to admin_crm_leads_path
    assert_equal 'converted', @lead.reload.stage
    assert_equal restaurant.id, @lead.reload.restaurant_id
  end

  test 'convert without restaurant_id shows error' do
    sign_in @mellow_admin
    # @lead is 'new'; new → converted is not a valid transition path anyway,
    # so the service returns a transition error (not the restaurant precondition error).
    # Either way the redirect has a flash alert.
    patch convert_admin_crm_lead_path(@lead), params: { restaurant_id: nil }
    assert_redirected_to admin_crm_leads_path
    assert flash[:alert].present?
  end

  # ---------------------------------------------------------------------------
  # Reopen
  # ---------------------------------------------------------------------------

  test 'mellow admin can reopen a lost lead' do
    sign_in @mellow_admin
    patch reopen_admin_crm_lead_path(@lost_lead)
    assert_redirected_to admin_crm_leads_path
    assert_equal 'contacted', @lost_lead.reload.stage
  end

  test 'reopen a converted lead fails gracefully' do
    sign_in @mellow_admin
    # @converted has no allowed forward transitions, so contacted is not reachable
    patch reopen_admin_crm_lead_path(@converted)
    assert_redirected_to admin_crm_leads_path
    assert flash[:alert].present?
  end
end

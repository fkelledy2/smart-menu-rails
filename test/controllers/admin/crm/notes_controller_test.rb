# frozen_string_literal: true

require 'test_helper'

class Admin::Crm::NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mellow_admin = users(:super_admin)
    @plain_admin  = users(:admin)
    @lead         = crm_leads(:new_lead)
    @note         = crm_lead_notes(:first_note)

    Flipper.enable(:crm_sales_funnel, @mellow_admin)
  end

  teardown do
    Flipper.disable(:crm_sales_funnel)
  end

  # ---------------------------------------------------------------------------
  # Create
  # ---------------------------------------------------------------------------

  test 'mellow admin can create a note' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadNote.count', 1 do
      post admin_crm_lead_notes_path(@lead),
           params: { crm_lead_note: { body: 'A new note body.' } },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    assert_response :ok
  end

  test 'create with empty body returns error' do
    sign_in @mellow_admin

    assert_no_difference 'CrmLeadNote.count' do
      post admin_crm_lead_notes_path(@lead),
           params: { crm_lead_note: { body: '' } }
    end
  end

  test 'non-mellow admin cannot create a note' do
    sign_in @plain_admin

    assert_no_difference 'CrmLeadNote.count' do
      post admin_crm_lead_notes_path(@lead),
           params: { crm_lead_note: { body: 'Attempted note' } }
    end

    assert_redirected_to root_path
  end

  test 'create writes a note_added audit record' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadAudit.count', 1 do
      post admin_crm_lead_notes_path(@lead),
           params: { crm_lead_note: { body: 'Audit check note.' } },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    audit = @lead.crm_lead_audits.order(:created_at).last
    assert_equal 'note_added', audit.event
  end

  # ---------------------------------------------------------------------------
  # Destroy
  # ---------------------------------------------------------------------------

  test 'mellow admin can destroy a note' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadNote.count', -1 do
      delete admin_crm_lead_note_path(@lead, @note),
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    assert_response :ok
  end

  test 'non-mellow admin cannot destroy a note' do
    sign_in @plain_admin

    assert_no_difference 'CrmLeadNote.count' do
      delete admin_crm_lead_note_path(@lead, @note)
    end

    assert_redirected_to root_path
  end
end

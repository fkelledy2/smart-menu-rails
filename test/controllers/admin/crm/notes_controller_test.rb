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

  test 'unauthenticated user cannot create a note' do
    assert_no_difference 'CrmLeadNote.count' do
      post admin_crm_lead_notes_path(@lead), params: { crm_lead_note: { body: 'Sneaky' } }
    end
    assert_response :redirect
  end

  test 'unauthenticated user cannot destroy a note' do
    assert_no_difference 'CrmLeadNote.count' do
      delete admin_crm_lead_note_path(@lead, @note)
    end
    assert_response :redirect
  end

  test 'create updates last_activity_at on the lead' do
    sign_in @mellow_admin
    old_activity = @lead.last_activity_at

    travel 1.minute do
      post admin_crm_lead_notes_path(@lead),
           params: { crm_lead_note: { body: 'Activity bump test' } },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    assert @lead.reload.last_activity_at > old_activity
  end

  test 'destroy writes a note_deleted audit with the note id in metadata' do
    sign_in @mellow_admin

    assert_difference 'CrmLeadAudit.count', 1 do
      delete admin_crm_lead_note_path(@lead, @note),
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    audit = @lead.crm_lead_audits.order(:created_at).last
    assert_equal 'note_deleted', audit.event
    assert_equal @note.id, audit.metadata['note_id']
  end

  test 'destroy updates last_activity_at on the lead' do
    sign_in @mellow_admin
    old_activity = @lead.last_activity_at

    travel 1.minute do
      delete admin_crm_lead_note_path(@lead, @note),
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    assert @lead.reload.last_activity_at > old_activity
  end

  test 'destroy returns 404 for a note that does not exist' do
    sign_in @mellow_admin
    delete admin_crm_lead_note_path(@lead, id: 0),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :not_found
  end

  test 'destroy cannot delete a note belonging to a different lead' do
    other_lead = crm_leads(:contacted_lead)
    other_note = other_lead.crm_lead_notes.create!(body: 'Other lead note', author: @mellow_admin)
    sign_in @mellow_admin

    # @lead.crm_lead_notes.find_by(id: other_note.id) returns nil — scoped to @lead
    assert_no_difference 'CrmLeadNote.count' do
      delete admin_crm_lead_note_path(@lead, other_note),
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end
    assert_response :not_found
  end

  test 'create redirects to lead show on plain HTML request' do
    sign_in @mellow_admin
    post admin_crm_lead_notes_path(@lead), params: { crm_lead_note: { body: 'HTML request note' } }
    assert_redirected_to admin_crm_lead_path(@lead)
  end

  test 'destroy redirects to lead show on plain HTML request' do
    sign_in @mellow_admin
    delete admin_crm_lead_note_path(@lead, @note)
    assert_redirected_to admin_crm_lead_path(@lead)
  end

  test 'create for a non-existent lead returns 404' do
    sign_in @mellow_admin
    post admin_crm_lead_notes_path(lead_id: 0), params: { crm_lead_note: { body: 'Ghost' } }
    assert_response :not_found
  end
end

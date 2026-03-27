# frozen_string_literal: true

require 'test_helper'

class CrmLeadNoteTest < ActiveSupport::TestCase
  test 'is valid with required fields' do
    lead = crm_leads(:new_lead)
    user = users(:super_admin)
    note = CrmLeadNote.new(crm_lead: lead, author: user, body: 'A test note.')
    assert note.valid?
  end

  test 'requires body' do
    lead = crm_leads(:new_lead)
    user = users(:super_admin)
    note = CrmLeadNote.new(crm_lead: lead, author: user, body: '')
    assert_not note.valid?
    assert_includes note.errors[:body], "can't be blank"
  end

  test 'requires crm_lead' do
    user = users(:super_admin)
    note = CrmLeadNote.new(author: user, body: 'Note without lead')
    assert_not note.valid?
  end

  test 'requires author' do
    lead = crm_leads(:new_lead)
    note = CrmLeadNote.new(crm_lead: lead, body: 'Note without author')
    assert_not note.valid?
  end

  test 'belongs to crm_lead' do
    note = crm_lead_notes(:first_note)
    assert_not_nil note.crm_lead
  end

  test 'belongs to author' do
    note = crm_lead_notes(:first_note)
    assert_not_nil note.author
  end
end

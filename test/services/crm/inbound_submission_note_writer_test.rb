# frozen_string_literal: true

require 'test_helper'

module Crm
  class InboundSubmissionNoteWriterTest < ActiveSupport::TestCase
    def setup
      @lead = crm_leads(:new_lead)
      @submission = WebsiteContactSubmission.create!(
        name:             'Test Person',
        email:            'test@example.com',
        phone:            '+353 87 000 0001',
        restaurant_name:  'Test Restaurant',
        message:          'I am very interested!',
        submitted_at:     Time.current,
        processing_status: 'pending',
      )
    end

    test 'creates a system-authored note on the lead' do
      assert_difference('@lead.crm_lead_notes.count', 1) do
        InboundSubmissionNoteWriter.call(crm_lead: @lead, submission: @submission)
      end

      note = @lead.crm_lead_notes.order(created_at: :desc).first
      assert note.created_by_system?
      assert_nil note.author_id
      assert_includes note.body, 'website contact form submission'
      assert_includes note.body, @submission.message
    end

    test 'note body includes submission email' do
      InboundSubmissionNoteWriter.call(crm_lead: @lead, submission: @submission)
      note = @lead.crm_lead_notes.order(created_at: :desc).first
      assert_includes note.body, @submission.email
    end

    test 'writes an inbound_submission_matched audit record' do
      assert_difference('CrmLeadAudit.count', 1) do
        InboundSubmissionNoteWriter.call(crm_lead: @lead, submission: @submission)
      end

      audit = CrmLeadAudit.order(created_at: :desc).first
      assert_equal 'inbound_submission_matched', audit.event
      assert_equal 'system', audit.actor_type
    end
  end
end

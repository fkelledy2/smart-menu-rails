# frozen_string_literal: true

require 'test_helper'

module Crm
  class ProcessWebsiteContactSubmissionJobTest < ActiveJob::TestCase
    def new_submission(overrides = {})
      WebsiteContactSubmission.create!({
        name:              'Job Test Person',
        email:             "job-test-#{SecureRandom.hex(4)}@newcafe.ie",
        restaurant_name:   'Job Test Cafe',
        message:           'I want to try mellow menu',
        submitted_at:      Time.current,
        processing_status: 'pending',
      }.merge(overrides))
    end

    # -------------------------------------------------------------------
    # Happy path — new lead created
    # -------------------------------------------------------------------
    test 'creates a new CrmLead when no matching lead exists' do
      sub = new_submission
      assert_difference('CrmLead.count', 1) do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end
      sub.reload
      assert_equal 'processed', sub.processing_status
      assert_not_nil sub.processed_at
      assert_not_nil sub.crm_lead_id
    end

    test 'sets source to website_inbound on new lead' do
      sub = new_submission
      ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      assert_equal 'website_inbound', sub.reload.crm_lead.source
    end

    test 'tags new lead with inbound and unsolicited' do
      sub = new_submission
      ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      lead = sub.reload.crm_lead
      tags = lead.crm_lead_tags.pluck(:tag).sort
      assert_equal %w[inbound unsolicited], tags
    end

    test 'writes lead_created audit record' do
      sub = new_submission
      assert_difference('CrmLeadAudit.count', 1) do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end
      audit = CrmLeadAudit.order(created_at: :desc).first
      assert_equal 'lead_created', audit.event
    end

    test 'enqueues inbound_lead_notification email' do
      sub = new_submission
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end
    end

    # -------------------------------------------------------------------
    # Deduplication — existing lead matched
    # -------------------------------------------------------------------
    test 'does not create duplicate lead when email matches existing lead' do
      existing_lead = crm_leads(:new_lead)
      sub = new_submission(email: existing_lead.contact_email) # same email

      assert_no_difference('CrmLead.count') do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end

      sub.reload
      assert_equal existing_lead.id, sub.crm_lead_id
      assert_equal 'processed', sub.processing_status
    end

    test 'appends a system note to matched lead' do
      existing_lead = crm_leads(:new_lead)
      sub = new_submission(email: existing_lead.contact_email)

      assert_difference('CrmLeadNote.count', 1) do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end

      note = existing_lead.crm_lead_notes.order(created_at: :desc).first
      assert note.created_by_system?
    end

    test 'does not overwrite manual source on existing matched lead' do
      existing_lead = crm_leads(:new_lead) # source: manual
      sub = new_submission(email: existing_lead.contact_email)
      ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      assert_equal 'manual', existing_lead.reload.source
    end

    # -------------------------------------------------------------------
    # Idempotency guard
    # -------------------------------------------------------------------
    test 'does not reprocess a submission that already has processed_at set' do
      sub = new_submission
      sub.update_columns(processed_at: Time.current, processing_status: 'processed')

      assert_no_difference('CrmLead.count') do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end
    end

    # -------------------------------------------------------------------
    # Spam guard
    # -------------------------------------------------------------------
    test 'skips already-spam-marked submissions' do
      sub = new_submission(processing_status: 'rejected_as_spam')
      assert_no_difference('CrmLead.count') do
        ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      end
    end

    test 'rejects disposable email submissions' do
      sub = new_submission(email: 'test@mailinator.com')
      ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
      assert_equal 'rejected_as_spam', sub.reload.processing_status
    end

    # -------------------------------------------------------------------
    # Error handling
    # -------------------------------------------------------------------
    test 'marks submission as failed and re-raises on unexpected error' do
      sub = new_submission
      # Force an error by making the submission update raise
      Crm::LeadMatcher.stub(:call, ->(**_) { raise 'Simulated error' }) do
        assert_raises(RuntimeError) do
          ProcessWebsiteContactSubmissionJob.perform_now(sub.id)
        end
      end
      assert_equal 'failed', sub.reload.processing_status
      assert_includes sub.error_message, 'Simulated error'
    end

    test 'returns early when submission_id is not found' do
      assert_no_difference('CrmLead.count') do
        ProcessWebsiteContactSubmissionJob.perform_now(99_999_999)
      end
    end
  end
end

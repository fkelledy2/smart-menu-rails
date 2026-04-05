# frozen_string_literal: true

require 'test_helper'

class WebsiteContactSubmissionTest < ActiveSupport::TestCase
  def valid_attrs
    {
      name:              'Alice Roberts',
      email:             'alice@example.com',
      message:           'Hello from the web',
      submitted_at:      Time.current,
      processing_status: 'pending',
    }
  end

  # -------------------------------------------------------------------
  # Validations
  # -------------------------------------------------------------------
  test 'valid with required fields' do
    sub = WebsiteContactSubmission.new(valid_attrs)
    assert sub.valid?, sub.errors.full_messages.inspect
  end

  test 'invalid without name' do
    sub = WebsiteContactSubmission.new(valid_attrs.except(:name))
    assert_not sub.valid?
    assert sub.errors[:name].present?
  end

  test 'invalid without email' do
    sub = WebsiteContactSubmission.new(valid_attrs.except(:email))
    assert_not sub.valid?
  end

  test 'invalid with malformed email' do
    sub = WebsiteContactSubmission.new(valid_attrs.merge(email: 'not-an-email'))
    assert_not sub.valid?
    assert sub.errors[:email].present?
  end

  test 'invalid without message' do
    sub = WebsiteContactSubmission.new(valid_attrs.except(:message))
    assert_not sub.valid?
  end

  test 'invalid without submitted_at' do
    sub = WebsiteContactSubmission.new(valid_attrs.except(:submitted_at))
    assert_not sub.valid?
  end

  test 'invalid with unknown processing_status' do
    sub = WebsiteContactSubmission.new(valid_attrs.merge(processing_status: 'banana'))
    assert_not sub.valid?
  end

  # -------------------------------------------------------------------
  # Immutability guard
  # -------------------------------------------------------------------
  test 'allows mutation of processing fields after create' do
    sub = WebsiteContactSubmission.create!(valid_attrs)
    sub.processing_status = 'processed'
    sub.processed_at      = Time.current
    assert sub.save
  end

  test 'raises on mutation of immutable fields after create' do
    sub = WebsiteContactSubmission.create!(valid_attrs)
    sub.name = 'Changed Name'
    assert_raises(ActiveRecord::ReadOnlyRecord) { sub.save! }
  end

  # -------------------------------------------------------------------
  # Scopes
  # -------------------------------------------------------------------
  test 'pending scope' do
    sub = website_contact_submissions(:pending_submission)
    assert_includes WebsiteContactSubmission.pending, sub
  end

  test 'rejected_as_spam scope' do
    sub = website_contact_submissions(:spam_submission)
    assert_includes WebsiteContactSubmission.rejected_as_spam, sub
  end

  test 'processed scope excludes pending' do
    pending_sub = website_contact_submissions(:pending_submission)
    assert_not_includes WebsiteContactSubmission.where(processing_status: 'processed'), pending_sub
  end

  # -------------------------------------------------------------------
  # Enum predicates
  # -------------------------------------------------------------------
  test 'status_pending? is correct' do
    sub = website_contact_submissions(:pending_submission)
    assert sub.status_pending?
    assert_not sub.status_processed?
  end

  test 'status_rejected_as_spam? is correct' do
    sub = website_contact_submissions(:spam_submission)
    assert sub.status_rejected_as_spam?
  end

  # -------------------------------------------------------------------
  # Association
  # -------------------------------------------------------------------
  test 'can belong to a crm_lead' do
    sub = website_contact_submissions(:processed_submission)
    assert_not_nil sub.crm_lead
  end

  test 'crm_lead is optional' do
    sub = website_contact_submissions(:pending_submission)
    assert_nil sub.crm_lead
  end
end

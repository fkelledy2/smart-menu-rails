# frozen_string_literal: true

require 'test_helper'

class Crm::SendLeadEmailJobTest < ActiveSupport::TestCase
  # Crm::SendLeadEmailJob finds lead + sender, then calls Crm::LeadEmailSender.call.
  # Tests verify early-return guards and the happy-path delegation.

  def setup
    @lead   = crm_leads(:new_lead)
    @sender = users(:admin)
  end

  test 'perform is a no-op when lead does not exist' do
    sender_called = false
    Crm::LeadEmailSender.stub(:call, ->(**_kwargs) { sender_called = true }) do
      Crm::SendLeadEmailJob.new.perform(
        crm_lead_id: -999,
        sender_id: @sender.id,
        to_email: 'to@test.com',
        subject: 'Hello',
        body_html: '<p>Hi</p>',
      )
    end

    assert_not sender_called, 'LeadEmailSender should not be called when lead is missing'
  end

  test 'perform is a no-op when sender user does not exist' do
    sender_called = false
    Crm::LeadEmailSender.stub(:call, ->(**_kwargs) { sender_called = true }) do
      Crm::SendLeadEmailJob.new.perform(
        crm_lead_id: @lead.id,
        sender_id: -999,
        to_email: 'to@test.com',
        subject: 'Hello',
        body_html: '<p>Hi</p>',
      )
    end

    assert_not sender_called, 'LeadEmailSender should not be called when sender is missing'
  end

  test 'perform calls LeadEmailSender when lead and sender both exist' do
    sender_called = false
    Crm::LeadEmailSender.stub(:call, ->(**_kwargs) { sender_called = true; nil }) do
      Crm::SendLeadEmailJob.new.perform(
        crm_lead_id: @lead.id,
        sender_id: @sender.id,
        to_email: 'recipient@test.com',
        subject: 'Follow up',
        body_html: '<p>Hello there</p>',
        body_text: 'Hello there',
        job_idempotency_key: 'key-abc-123',
      )
    end

    assert sender_called, 'LeadEmailSender.call should have been invoked'
  end

  test 'job uses mailers or default queue' do
    queue = Crm::SendLeadEmailJob.sidekiq_options_hash['queue']
    assert queue.present?, 'queue should be configured'
  end
end

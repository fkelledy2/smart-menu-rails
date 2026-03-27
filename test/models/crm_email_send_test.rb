# frozen_string_literal: true

require 'test_helper'

class CrmEmailSendTest < ActiveSupport::TestCase
  test 'is valid with required fields' do
    lead   = crm_leads(:contacted_lead)
    sender = users(:super_admin)
    es = CrmEmailSend.new(crm_lead: lead, sender: sender, to_email: 'test@example.com', subject: 'Hello')
    assert es.valid?
  end

  test 'requires to_email' do
    lead   = crm_leads(:contacted_lead)
    sender = users(:super_admin)
    es = CrmEmailSend.new(crm_lead: lead, sender: sender, subject: 'Hello')
    assert_not es.valid?
    assert es.errors[:to_email].any?
  end

  test 'requires subject' do
    lead   = crm_leads(:contacted_lead)
    sender = users(:super_admin)
    es = CrmEmailSend.new(crm_lead: lead, sender: sender, to_email: 'test@example.com')
    assert_not es.valid?
    assert es.errors[:subject].any?
  end

  test 'belongs to crm_lead' do
    es = crm_email_sends(:first_email)
    assert_not_nil es.crm_lead
  end

  test 'belongs to sender' do
    es = crm_email_sends(:first_email)
    assert_not_nil es.sender
  end
end

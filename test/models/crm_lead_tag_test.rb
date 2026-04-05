# frozen_string_literal: true

require 'test_helper'

class CrmLeadTagTest < ActiveSupport::TestCase
  def setup
    @lead = crm_leads(:new_lead)
  end

  test 'valid with valid tag' do
    tag = CrmLeadTag.new(crm_lead: @lead, tag: 'inbound')
    assert tag.valid?
  end

  test 'invalid with blank tag' do
    tag = CrmLeadTag.new(crm_lead: @lead, tag: '')
    assert_not tag.valid?
    assert_includes tag.errors[:tag], 'is not included in the list'
  end

  test 'invalid with unknown tag' do
    tag = CrmLeadTag.new(crm_lead: @lead, tag: 'vip')
    assert_not tag.valid?
    assert_includes tag.errors[:tag], 'is not included in the list'
  end

  test 'invalid without crm_lead' do
    tag = CrmLeadTag.new(tag: 'inbound')
    assert_not tag.valid?
  end

  test 'uniqueness enforced per crm_lead and tag' do
    CrmLeadTag.create!(crm_lead: @lead, tag: 'inbound')
    dup = CrmLeadTag.new(crm_lead: @lead, tag: 'inbound')
    assert_not dup.valid?
    assert_includes dup.errors[:crm_lead_id], 'already has this tag'
  end

  test 'allows same tag on different leads' do
    other_lead = crm_leads(:contacted_lead)
    CrmLeadTag.create!(crm_lead: @lead, tag: 'inbound')
    tag2 = CrmLeadTag.new(crm_lead: other_lead, tag: 'inbound')
    assert tag2.valid?
  end

  test 'fixture tags are valid' do
    assert crm_lead_tags(:inbound_tag).valid?
    assert crm_lead_tags(:unsolicited_tag).valid?
  end
end

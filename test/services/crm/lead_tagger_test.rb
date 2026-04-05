# frozen_string_literal: true

require 'test_helper'

module Crm
  class LeadTaggerTest < ActiveSupport::TestCase
    def setup
      @lead = crm_leads(:new_lead)
    end

    test 'applies specified tags to a lead' do
      result = LeadTagger.call(crm_lead: @lead, tags: %w[unsolicited inbound])
      assert_equal 2, result.size
      assert_equal %w[inbound unsolicited], @lead.crm_lead_tags.order(:tag).pluck(:tag)
    end

    test 'is idempotent — does not create duplicate tags' do
      LeadTagger.call(crm_lead: @lead, tags: %w[inbound])
      assert_no_difference('CrmLeadTag.count') do
        LeadTagger.call(crm_lead: @lead, tags: %w[inbound])
      end
    end

    test 'ignores unknown tags silently' do
      result = LeadTagger.call(crm_lead: @lead, tags: %w[inbound vip unknown])
      assert_equal 1, result.size # only 'inbound' is valid
    end

    test 'handles empty tag list' do
      result = LeadTagger.call(crm_lead: @lead, tags: [])
      assert_equal [], result
    end

    test 'fixture lead already has inbound + unsolicited tags' do
      lead = crm_leads(:website_inbound_lead)
      assert_equal 2, lead.crm_lead_tags.count
    end
  end
end

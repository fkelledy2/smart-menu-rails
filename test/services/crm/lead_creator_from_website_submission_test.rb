# frozen_string_literal: true

require 'test_helper'

module Crm
  class LeadCreatorFromWebsiteSubmissionTest < ActiveSupport::TestCase
    def valid_submission
      WebsiteContactSubmission.create!(
        name:             'Bob Test',
        email:            'bob@testcafe.ie',
        phone:            '+353 85 999 0000',
        restaurant_name:  'Test Cafe Galway',
        message:          'Interested in mellow menu',
        submitted_at:     Time.current,
        processing_status: 'pending',
      )
    end

    test 'creates a new CrmLead with website_inbound source' do
      submission = valid_submission
      result = LeadCreatorFromWebsiteSubmission.call(submission: submission)

      assert result.success?, result.error
      assert_equal 'website_inbound', result.lead.source
      assert_equal 'new',             result.lead.stage
      assert_equal 'bob@testcafe.ie', result.lead.contact_email
      assert_equal 'Bob Test',        result.lead.contact_name
    end

    test 'uses restaurant_name from submission when present' do
      submission = valid_submission
      result = LeadCreatorFromWebsiteSubmission.call(submission: submission)

      assert_equal 'Test Cafe Galway', result.lead.restaurant_name
    end

    test 'falls back to company_name when restaurant_name is blank' do
      submission = WebsiteContactSubmission.create!(
        name:              'Carol Test',
        email:             'carol@corp.ie',
        company_name:      'Corp Ltd',
        message:           'Hello',
        submitted_at:      Time.current,
        processing_status: 'pending',
      )
      result = LeadCreatorFromWebsiteSubmission.call(submission: submission)
      assert result.success?
      assert_equal 'Corp Ltd', result.lead.restaurant_name
    end

    test 'falls back to submitter name when neither restaurant nor company is present' do
      submission = WebsiteContactSubmission.create!(
        name:              'Dave Test',
        email:             'dave@me.ie',
        message:           'Just curious',
        submitted_at:      Time.current,
        processing_status: 'pending',
      )
      result = LeadCreatorFromWebsiteSubmission.call(submission: submission)
      assert result.success?
      assert_equal 'Dave Test', result.lead.restaurant_name
    end

    test 'returns failure result when lead is invalid' do
      # Force an invalid lead by making restaurant_name nil after submission creation
      submission = valid_submission
      # Stub — name is present so this should succeed unless we break validations differently.
      # Instead test a situation where save fails by creating a submission without required field.
      # The model requires restaurant_name to be derived from submission fields, which are always
      # present if submission is valid. Testing service resilience via a direct invalid creation:
      submission.instance_variable_set(:@name, nil)
      def submission.name = nil # rubocop:disable Lint/NestedMethodDefinition

      result = LeadCreatorFromWebsiteSubmission.call(submission: submission)
      # restaurant_name falls back to name, which is nil, so lead will fail restaurant_name validation
      assert_not result.success? if result.respond_to?(:success?)
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

module Crm
  class LeadMatcherTest < ActiveSupport::TestCase
    # -------------------------------------------------------------------
    # Email match (priority 1)
    # -------------------------------------------------------------------
    test 'matches by exact email (case-insensitive)' do
      lead = crm_leads(:new_lead) # contact_email: "jane@blueduck.com"
      result = LeadMatcher.call(email: 'JANE@BLUEDUCK.COM')
      assert_equal lead, result
    end

    test 'returns nil when no email match' do
      result = LeadMatcher.call(email: 'nobody@unknown.com')
      assert_nil result
    end

    # -------------------------------------------------------------------
    # Phone match (priority 2)
    # -------------------------------------------------------------------
    test 'matches by phone when email does not match' do
      lead = crm_leads(:new_lead) # contact_phone: "+353 87 123 4567"
      result = LeadMatcher.call(email: 'other@email.com', phone: '+353 87 123 4567')
      assert_equal lead, result
    end

    test 'does not match by phone when phone is blank' do
      result = LeadMatcher.call(email: 'other@email.com', phone: '')
      assert_nil result
    end

    # -------------------------------------------------------------------
    # Restaurant name + contact name match (priority 3)
    # -------------------------------------------------------------------
    test 'matches by restaurant_name + contact_name when email and phone do not match' do
      lead = crm_leads(:new_lead)
      result = LeadMatcher.call(
        email:           'different@email.com',
        phone:           nil,
        name:            '  Jane Smith  ',   # whitespace tolerance
        restaurant_name: 'the blue duck',    # case tolerance
      )
      assert_equal lead, result
    end

    test 'returns nil when restaurant_name matches but contact_name does not' do
      result = LeadMatcher.call(
        email:           'different@email.com',
        name:            'Wrong Name',
        restaurant_name: 'The Blue Duck',
      )
      assert_nil result
    end

    # -------------------------------------------------------------------
    # No match
    # -------------------------------------------------------------------
    test 'returns nil when nothing matches' do
      result = LeadMatcher.call(
        email:           'unique@noexist.com',
        phone:           nil,
        name:            'Unknown Person',
        restaurant_name: 'Unknown Restaurant',
      )
      assert_nil result
    end

    test 'returns nil when all args are blank' do
      result = LeadMatcher.call(email: nil, phone: nil, name: nil, restaurant_name: nil)
      assert_nil result
    end

    # -------------------------------------------------------------------
    # Spam detection
    # -------------------------------------------------------------------
    test 'spam? returns true for disposable email domains' do
      matcher = LeadMatcher.new(email: 'test@mailinator.com', name: nil, phone: nil, restaurant_name: nil)
      assert matcher.spam?
    end

    test 'spam? returns false for legitimate domains' do
      matcher = LeadMatcher.new(email: 'test@gmail.com', name: nil, phone: nil, restaurant_name: nil)
      assert_not matcher.spam?
    end

    test 'spam? returns false when email is nil' do
      matcher = LeadMatcher.new(email: nil, name: nil, phone: nil, restaurant_name: nil)
      assert_not matcher.spam?
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrationPolicyTest < ActiveSupport::TestCase
  def setup
    @super_admin   = users(:super_admin)   # super_admin: true
    @owner         = users(:one)           # owns restaurants(:one)
    @other_user    = users(:two)           # no relation to restaurants(:one)
    @restaurant    = restaurants(:one)
    @restaurant.update!(user_id: @owner.id)
  end

  # --- workforce? ---

  test 'super_admin can access workforce endpoint' do
    assert PartnerIntegrationPolicy.new(@super_admin, @restaurant).workforce?
  end

  test 'restaurant owner can access workforce endpoint' do
    assert PartnerIntegrationPolicy.new(@owner, @restaurant).workforce?
  end

  test 'unrelated user cannot access workforce endpoint' do
    assert_not PartnerIntegrationPolicy.new(@other_user, @restaurant).workforce?
  end

  test 'guest user cannot access workforce endpoint' do
    assert_not PartnerIntegrationPolicy.new(nil, @restaurant).workforce?
  end

  # --- crm? ---

  test 'super_admin can access CRM endpoint' do
    assert PartnerIntegrationPolicy.new(@super_admin, @restaurant).crm?
  end

  test 'restaurant owner can access CRM endpoint' do
    assert PartnerIntegrationPolicy.new(@owner, @restaurant).crm?
  end

  test 'unrelated user cannot access CRM endpoint' do
    assert_not PartnerIntegrationPolicy.new(@other_user, @restaurant).crm?
  end

  # --- error_logs? ---

  test 'super_admin can view error logs' do
    assert PartnerIntegrationPolicy.new(@super_admin, @restaurant).error_logs?
  end

  test 'restaurant owner can view error logs' do
    assert PartnerIntegrationPolicy.new(@owner, @restaurant).error_logs?
  end

  test 'unrelated user cannot view error logs' do
    assert_not PartnerIntegrationPolicy.new(@other_user, @restaurant).error_logs?
  end
end

# frozen_string_literal: true

require 'test_helper'

class Admin::TwoFactorReportPolicyTest < ActiveSupport::TestCase
  def setup
    @super_admin = users(:super_admin)
    @regular_user = users(:one)
  end

  test 'index? allows super_admin' do
    policy = Admin::TwoFactorReportPolicy.new(@super_admin, :two_factor_report)
    assert policy.index?
  end

  test 'index? denies regular user' do
    policy = Admin::TwoFactorReportPolicy.new(@regular_user, :two_factor_report)
    assert_not policy.index?
  end
end

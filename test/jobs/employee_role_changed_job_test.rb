require 'test_helper'

class EmployeeRoleChangedJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def setup
    @audit = employee_role_audits(:one)
  end

  test 'performs successfully and delivers email' do
    assert_emails 1 do
      EmployeeRoleChangedJob.perform_now(@audit.id)
    end
  end

  test 'does nothing when audit record does not exist' do
    assert_emails 0 do
      assert_nothing_raised do
        EmployeeRoleChangedJob.perform_now(99_999_999)
      end
    end
  end

  test 'is queued on the default queue' do
    assert_equal 'default', EmployeeRoleChangedJob.new.queue_name
  end
end

require 'test_helper'

class Payments::ReconciliationJobTest < ActiveJob::TestCase
  test 'job runs without error' do
    assert_nothing_raised do
      Payments::ReconciliationJob.perform_now(provider: 'stripe', since: 1.hour.ago)
    end
  end
end

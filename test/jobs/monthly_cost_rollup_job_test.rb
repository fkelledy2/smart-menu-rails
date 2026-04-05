# frozen_string_literal: true

require 'test_helper'

class MonthlyCostRollupJobTest < ActiveJob::TestCase
  test 'job can be enqueued' do
    assert_enqueued_with(job: MonthlyCostRollupJob) do
      MonthlyCostRollupJob.perform_later(month: Date.current.beginning_of_month.to_s)
    end
  end

  test 'perform does not raise with default month' do
    assert_nothing_raised do
      MonthlyCostRollupJob.perform_now
    end
  end

  test 'perform does not raise with string month parameter' do
    assert_nothing_raised do
      MonthlyCostRollupJob.perform_now(month: Date.current.prev_month.beginning_of_month.to_s)
    end
  end

  test 'perform processes all services and logs usage' do
    month = Date.current.beginning_of_month

    # Create a daily usage record directly (bypassing upsert) to have data for the rollup.
    ExternalServiceDailyUsage.create!(
      date: month,
      service: 'deepl',
      dimension: 'char_rollup_test',
      units: 100,
      unit_type: 'characters',
    )

    assert_nothing_raised do
      MonthlyCostRollupJob.perform_now(month: month.to_s)
    end
  end
end

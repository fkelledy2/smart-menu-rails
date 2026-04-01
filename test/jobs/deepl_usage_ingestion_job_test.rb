# frozen_string_literal: true

require 'test_helper'

class DeeplUsageIngestionJobTest < ActiveJob::TestCase
  test 'job can be enqueued' do
    assert_enqueued_with(job: DeeplUsageIngestionJob) do
      DeeplUsageIngestionJob.perform_later(date: Date.yesterday.to_s)
    end
  end

  test 'perform does not raise when DeepL is not configured' do
    # Without a real API key, the service returns an error result (not an exception)
    assert_nothing_raised do
      DeeplUsageIngestionJob.perform_now(date: Date.yesterday.to_s)
    end
  end
end

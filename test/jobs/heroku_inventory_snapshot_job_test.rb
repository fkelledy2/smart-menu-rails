# frozen_string_literal: true

require 'test_helper'

class HerokuInventorySnapshotJobTest < ActiveJob::TestCase
  test 'job creates snapshot records in mock mode' do
    count_before = HerokuAppInventorySnapshot.count

    HerokuInventorySnapshotJob.perform_now(space_name: 'smart-menu')

    assert HerokuAppInventorySnapshot.count > count_before
  end

  test 'snapshot records have correct space_name' do
    HerokuInventorySnapshotJob.perform_now(space_name: 'test-space')

    snaps = HerokuAppInventorySnapshot.for_space('test-space').order(captured_at: :desc).limit(10)
    snaps.each { |s| assert_equal 'test-space', s.space_name }
  end

  test 'snapshot records have valid environments' do
    HerokuInventorySnapshotJob.perform_now(space_name: 'smart-menu')

    recent = HerokuAppInventorySnapshot.order(captured_at: :desc).limit(10)
    recent.each do |snap|
      assert_includes HerokuAppInventorySnapshot::ENVIRONMENTS, snap.environment,
                      "Expected #{snap.environment} to be a valid environment"
    end
  end

  test 'job can be enqueued' do
    assert_enqueued_with(job: HerokuInventorySnapshotJob) do
      HerokuInventorySnapshotJob.perform_later(space_name: 'smart-menu')
    end
  end
end

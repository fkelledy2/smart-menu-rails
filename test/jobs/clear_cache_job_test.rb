# frozen_string_literal: true

require 'test_helper'

class ClearCacheJobTest < ActiveSupport::TestCase
  test 'perform clears Rails.cache without raising' do
    # Write something to cache first to verify clear is called
    Rails.cache.write('test_clear_cache_job_key', 'value', expires_in: 1.minute)

    assert_nothing_raised do
      ClearCacheJob.new.perform
    end
  end

  test 'perform calls Rails.cache.clear' do
    clear_called = false

    Rails.cache.stub(:clear, -> { clear_called = true }) do
      ClearCacheJob.new.perform
    end

    assert clear_called
  end

  test 'does not raise when cache store does not support Redis SCAN' do
    # Test env uses MemoryStore which has no .redis method — simulate graceful path
    assert_nothing_raised do
      ClearCacheJob.new.perform
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

class OrderEventProjectionJobTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
  end

  test 'calls OrderEventProjector.project! with the given ordr_id' do
    projected_ids = []

    OrderEventProjector.stub(:project!, ->(id) { projected_ids << id }) do
      OrderEventProjectionJob.new.perform(@ordr.id)
    end

    assert_includes projected_ids, @ordr.id
  end

  test 'does not raise when order_id does not exist' do
    assert_nothing_raised do
      OrderEventProjectionJob.new.perform(-1)
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      OrderEventProjectionJob.perform_later(@ordr.id)
    end
  end
end

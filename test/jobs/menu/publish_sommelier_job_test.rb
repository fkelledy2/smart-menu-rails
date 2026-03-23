# frozen_string_literal: true

require 'test_helper'

class Menu::PublishSommelierJobTest < ActiveSupport::TestCase
  def setup
    @job = Menu::PublishSommelierJob.new
  end

  test 'does nothing when pipeline run does not exist' do
    assert_nothing_raised do
      @job.perform(-999_999)
    end
  end

  test 'marks pipeline run as succeeded' do
    run = BeveragePipelineRun.create!(
      menu: menus(:one),
      restaurant: restaurants(:one),
      status: 'running',
    )
    @job.perform(run.id)
    run.reload
    assert_equal 'succeeded', run.status
    assert_equal 'publish', run.current_step
    assert_not_nil run.completed_at
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      Menu::PublishSommelierJob.perform_async(-999_999)
    end
  end
end

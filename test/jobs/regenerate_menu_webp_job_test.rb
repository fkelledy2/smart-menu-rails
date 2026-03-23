# frozen_string_literal: true

require 'test_helper'

class RegenerateMenuWebpJobTest < ActiveSupport::TestCase
  def setup
    @job = RegenerateMenuWebpJob.new
  end

  test 'does nothing when menu does not exist' do
    assert_nothing_raised do
      @job.perform(-999_999)
    end
  end

  test 'performs without error for valid menu with no images' do
    menu = menus(:one)
    assert_nothing_raised do
      @job.perform(menu.id)
    end
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      RegenerateMenuWebpJob.perform_async(menus(:one).id)
    end
  end
end

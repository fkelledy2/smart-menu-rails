# frozen_string_literal: true

require 'test_helper'

class Menu::BeveragePipelineStartJobTest < ActiveSupport::TestCase
  def setup
    @job = Menu::BeveragePipelineStartJob.new
  end

  test 'does nothing when menu does not exist' do
    assert_nothing_raised do
      @job.perform(-999_999, -999_999)
    end
  end

  test 'does nothing when restaurant does not exist' do
    assert_nothing_raised do
      @job.perform(menus(:one).id, -999_999)
    end
  end

  test 'does not start pipeline when one is already running' do
    menu = menus(:one)
    restaurant = restaurants(:one)
    BeveragePipelineRun.create!(menu: menu, restaurant: restaurant, status: 'running')

    assert_no_difference 'BeveragePipelineRun.count' do
      @job.perform(menu.id, restaurant.id)
    end
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      Menu::BeveragePipelineStartJob.perform_async(-999_999, -999_999)
    end
  end
end

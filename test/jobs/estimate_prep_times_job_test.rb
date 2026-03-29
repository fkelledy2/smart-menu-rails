# frozen_string_literal: true

require 'test_helper'

class EstimatePrepTimesJobTest < ActiveSupport::TestCase
  # =========================================================================
  # heuristic estimation — pure logic, no external calls
  # =========================================================================

  def job
    EstimatePrepTimesJob.new
  end

  # Test the heuristic estimator indirectly by ensuring the job runs without raising
  # and that the heuristic paths are exercised via perform with real menuitems

  test 'does not raise when performing on a specific menu' do
    ENV.delete('OPENAI_API_KEY') # ensure LLM client is nil so only heuristic runs
    menu = menus(:one)

    assert_nothing_raised do
      EstimatePrepTimesJob.new.perform(menu.id)
    end
  end

  test 'does not raise when performing on all items (no menu_id)' do
    ENV.delete('OPENAI_API_KEY')

    assert_nothing_raised do
      EstimatePrepTimesJob.new.perform
    end
  end

  test 'does not raise for missing menu_id' do
    assert_nothing_raised do
      EstimatePrepTimesJob.new.perform(-999_999)
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      EstimatePrepTimesJob.perform_async
    end
  end

  # =========================================================================
  # estimate_heuristic — covered via perform on items with known name patterns
  # The heuristic is a private method so we exercise it through the public perform interface
  # with items that have preptime=0 so the estimation logic runs
  # =========================================================================

  test 'estimates prep time for a braised item and writes it' do
    ENV.delete('OPENAI_API_KEY')
    item = menuitems(:one)
    item.update_column(:preptime, 0)
    item.update_column(:name, 'Braised Short Rib')
    item.update_column(:description, 'slow cook for 6 hours')

    menu = item.menusection.menu

    EstimatePrepTimesJob.new.perform(menu.id)

    item.reload
    assert item.preptime.to_i.positive?, "Expected preptime to be set, got #{item.preptime}"
  end

  test 'skips items that already have a preptime' do
    ENV.delete('OPENAI_API_KEY')
    item = menuitems(:one)
    item.update_column(:preptime, 15)

    menu = item.menusection.menu
    item.reload.updated_at

    EstimatePrepTimesJob.new.perform(menu.id)

    item.reload
    assert_equal 15, item.preptime
  end
end

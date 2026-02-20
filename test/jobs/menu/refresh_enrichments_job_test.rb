# frozen_string_literal: true

require 'test_helper'

class Menu::RefreshEnrichmentsJobTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test 'returns 0 when no stale enrichments exist' do
    result = Menu::RefreshEnrichmentsJob.new.perform(10)
    assert_equal 0, result
  end

  test 'returns early for non-existent run without error' do
    assert_nothing_raised do
      Menu::RefreshEnrichmentsJob.new.perform(0)
    end
  end
end

require 'test_helper'

class BeveragePipelineRunTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @run = BeveragePipelineRun.new(
      restaurant: @restaurant,
      menu: @menu,
      status: 'completed',
    )
  end

  test 'valid run saves' do
    assert @run.save
  end

  test 'requires status' do
    @run.status = nil
    assert_not @run.valid?
    assert_includes @run.errors[:status], "can't be blank"
  end

  test 'belongs to restaurant' do
    @run.save!
    assert_equal @restaurant, @run.restaurant
  end

  test 'belongs to menu' do
    @run.save!
    assert_equal @menu, @run.menu
  end

  test 'running scope returns running records' do
    @run.status = 'running'
    @run.save!
    assert_includes BeveragePipelineRun.running, @run
  end

  test 'running scope excludes non-running records' do
    @run.status = 'completed'
    @run.save!
    assert_not_includes BeveragePipelineRun.running, @run
  end

  test 'recent scope orders by created_at desc' do
    @run.save!
    second = BeveragePipelineRun.create!(restaurant: @restaurant, menu: @menu, status: 'running')
    recent_ids = BeveragePipelineRun.recent.pluck(:id)
    assert recent_ids.index(second.id) < recent_ids.index(@run.id)
  end
end

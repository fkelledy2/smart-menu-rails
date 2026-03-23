require 'test_helper'

class AlcoholOrderEventTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @ordritem = ordritems(:one)
    @menuitem = menuitems(:burger)
    @event = AlcoholOrderEvent.new(
      ordr: @ordr,
      ordritem: @ordritem,
      menuitem: @menuitem,
      restaurant: @restaurant,
    )
  end

  test 'valid event saves' do
    assert @event.save
  end

  test 'abv can be nil' do
    @event.abv = nil
    assert @event.valid?
  end

  test 'abv must be >= 0' do
    @event.abv = -1
    assert_not @event.valid?
    assert_includes @event.errors[:abv], 'must be greater than or equal to 0'
  end

  test 'abv must be <= 100' do
    @event.abv = 101
    assert_not @event.valid?
    assert_includes @event.errors[:abv], 'must be less than or equal to 100'
  end

  test 'abv can be 0' do
    @event.abv = 0
    assert @event.valid?
  end

  test 'abv can be 100' do
    @event.abv = 100
    assert @event.valid?
  end

  test 'acknowledged scope returns events where age_check_acknowledged is true' do
    @event.age_check_acknowledged = true
    @event.save!
    assert_includes AlcoholOrderEvent.acknowledged, @event
  end

  test 'acknowledged scope excludes unacknowledged events' do
    @event.age_check_acknowledged = false
    @event.save!
    assert_not_includes AlcoholOrderEvent.acknowledged, @event
  end

  test 'belongs to restaurant' do
    @event.save!
    assert_equal @restaurant, @event.restaurant
  end
end

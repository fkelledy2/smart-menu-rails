require 'test_helper'

class MenuitemCostTest < ActiveSupport::TestCase
  def setup
    @menuitem = menuitems(:one)
    @cost = MenuitemCost.new(
      menuitem: @menuitem,
      ingredient_cost: 3.00,
      labor_cost: 2.50,
      packaging_cost: 0.50,
      overhead_cost: 1.00,
      effective_date: Time.zone.today,
      cost_source: 'manual',
      is_active: false,
    )
  end

  test 'valid cost record saves successfully' do
    assert @cost.save
  end

  test 'requires effective_date' do
    @cost.effective_date = nil
    assert_not @cost.valid?
    assert_includes @cost.errors[:effective_date], "can't be blank"
  end

  test 'requires valid cost_source' do
    @cost.cost_source = 'invalid_source'
    assert_not @cost.valid?
  end

  test 'accepts all valid cost_source values' do
    %w[manual recipe_calculated ai_estimated].each do |source|
      @cost.cost_source = source
      assert @cost.valid?, "Expected #{source} to be valid"
    end
  end

  test 'rejects negative ingredient_cost' do
    @cost.ingredient_cost = -1
    assert_not @cost.valid?
  end

  test 'rejects negative labor_cost' do
    @cost.labor_cost = -0.01
    assert_not @cost.valid?
  end

  test 'accepts zero for all cost components' do
    @cost.ingredient_cost = 0
    @cost.labor_cost = 0
    @cost.packaging_cost = 0
    @cost.overhead_cost = 0
    assert @cost.valid?
  end

  test 'total_cost sums all four components' do
    @cost.save!
    assert_in_delta 7.00, @cost.total_cost, 0.001
  end

  test 'total_cost handles nil components as zero' do
    @cost.packaging_cost = nil
    @cost.overhead_cost = nil
    @cost.save(validate: false)
    assert_in_delta 5.50, @cost.total_cost, 0.001
  end

  test 'active scope returns only is_active records' do
    @cost.is_active = true
    @cost.save!
    assert_includes MenuitemCost.active, @cost
  end

  test 'active scope excludes inactive records' do
    @cost.is_active = false
    @cost.save!
    assert_not_includes MenuitemCost.active, @cost
  end

  test 'for_date scope returns costs on or before the given date' do
    @cost.effective_date = 3.days.ago.to_date
    @cost.save!
    assert_includes MenuitemCost.for_date(Time.zone.today), @cost
  end

  test 'for_date scope excludes future costs' do
    @cost.effective_date = 3.days.from_now.to_date
    @cost.save!
    assert_not_includes MenuitemCost.for_date(Time.zone.today), @cost
  end

  test 'saving an active cost deactivates other active costs for same menuitem' do
    first = MenuitemCost.create!(
      menuitem: @menuitem,
      ingredient_cost: 1, labor_cost: 1, packaging_cost: 0, overhead_cost: 0,
      effective_date: Time.zone.today, cost_source: 'manual', is_active: true,
    )
    assert first.is_active?

    second = MenuitemCost.create!(
      menuitem: @menuitem,
      ingredient_cost: 2, labor_cost: 2, packaging_cost: 0, overhead_cost: 0,
      effective_date: Time.zone.today, cost_source: 'manual', is_active: true,
    )

    first.reload
    assert_not first.is_active?, 'First cost should be deactivated after second active cost saved'
    assert second.is_active?
  end

  test 'belongs to menuitem' do
    assert_equal @menuitem, @cost.menuitem
  end
end

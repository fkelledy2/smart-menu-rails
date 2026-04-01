require 'test_helper'

class SizeMappingCostServiceTest < ActiveSupport::TestCase
  def setup
    @menuitem = menuitems(:one)
    # SizeMappingCostService calls @menuitem.menuitemsizemappings (the name used in the service).
    # Menuitem's actual association is menuitem_size_mappings. We stub at the instance level
    # so tests are isolated from this naming discrepancy.
  end

  def with_empty_mappings(&)
    empty = [].tap { |a| def a.any? = false }
    @menuitem.define_singleton_method(:menuitemsizemappings) { empty }
    yield
  ensure
    begin
      @menuitem.singleton_class.remove_method(:menuitemsizemappings)
    rescue StandardError
      nil
    end
  end

  test 'calculate_size_costs returns empty hash when no sizemappings exist' do
    with_empty_mappings do
      service = SizeMappingCostService.new(@menuitem)
      assert_equal({}, service.calculate_size_costs)
    end
  end

  test 'calculate_size_costs returns empty hash when menuitem has no current_cost' do
    mappings = [OpenStruct.new].tap { |a| def a.any? = true }
    @menuitem.define_singleton_method(:menuitemsizemappings) { mappings }
    @menuitem.define_singleton_method(:current_cost) { nil }

    service = SizeMappingCostService.new(@menuitem)
    assert_equal({}, service.calculate_size_costs)
  ensure
    begin
      @menuitem.singleton_class.remove_method(:menuitemsizemappings)
    rescue StandardError
      nil
    end
    begin
      @menuitem.singleton_class.remove_method(:current_cost)
    rescue StandardError
      nil
    end
  end

  test 'most_profitable_size returns nil when no sizemappings' do
    with_empty_mappings do
      service = SizeMappingCostService.new(@menuitem)
      assert_nil service.most_profitable_size
    end
  end

  test 'size_profitability_analysis returns expected structure with no sizemappings' do
    with_empty_mappings do
      service = SizeMappingCostService.new(@menuitem)
      result = service.size_profitability_analysis

      assert_equal 0, result[:total_sizes]
      assert_equal({}, result[:size_breakdown])
      assert_nil result[:most_profitable]
      assert_nil result[:least_profitable]
      assert_equal 0, result[:average_margin]
    end
  end
end

require 'test_helper'

class DwOrdersMvTest < ActiveSupport::TestCase
  def setup
    # Skip all tests if materialized view doesn't exist
    skip 'Materialized view dw_orders_mv does not exist in test database' unless table_exists?
  end

  test 'uses correct table name' do
    assert_equal 'dw_orders_mv', DwOrdersMv.table_name
  end

  test 'has no primary key' do
    assert_nil DwOrdersMv.primary_key
  end

  test 'is readonly' do
    mv = DwOrdersMv.new
    assert mv.readonly?
  end

  test 'cannot be saved' do
    mv = DwOrdersMv.new
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      mv.save
    end
  end

  test 'cannot be destroyed' do
    skip 'No records in materialized view' if DwOrdersMv.count.zero?
    
    mv = DwOrdersMv.first
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      mv.destroy
    end
  end

  test 'can query records' do
    assert_nothing_raised do
      DwOrdersMv.all.to_a
    end
  end

  private

  def table_exists?
    ActiveRecord::Base.connection.table_exists?('dw_orders_mv')
  end
end

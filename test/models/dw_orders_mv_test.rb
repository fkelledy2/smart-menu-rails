require 'test_helper'

class DwOrdersMvTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    create_test_materialized_view unless table_exists?
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
    skip 'No records in materialized view' if DwOrdersMv.none?

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

  def create_test_materialized_view
    sql = <<~SQL.squish
      CREATE MATERIALIZED VIEW IF NOT EXISTS dw_orders_mv AS
      SELECT
        1::bigint AS ordr_id,
        1::bigint AS restaurant_id,
        CURRENT_DATE AS ordered_on,
        0.0::numeric AS gross;
    SQL

    ActiveRecord::Base.connection.execute(sql)
    
    # Populate the materialized view
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW dw_orders_mv')
  end

  def table_exists?
    ActiveRecord::Base.connection.table_exists?('dw_orders_mv')
  end
end

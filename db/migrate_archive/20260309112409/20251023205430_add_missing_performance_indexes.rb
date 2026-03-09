class AddMissingPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # Add missing foreign key indexes
    add_index :pay_merchants, :processor_id unless index_exists?(:pay_merchants, :processor_id)
    add_index :pay_subscriptions, :payment_method_id unless index_exists?(:pay_subscriptions, :payment_method_id)

    # Add composite indexes for common query patterns
    # These improve performance for queries that filter by multiple columns

    # Orders by table and status (common in order management)
    unless index_exists?(:ordrs, %i[tablesetting_id status])
      add_index :ordrs, %i[tablesetting_id status],
                name: 'index_ordrs_on_tablesetting_and_status'
    end

    # Menu sections ordered by sequence (common in menu display)
    unless index_exists?(:menusections, %i[menu_id sequence])
      add_index :menusections, %i[menu_id sequence],
                name: 'index_menusections_on_menu_and_sequence'
    end
  end
end

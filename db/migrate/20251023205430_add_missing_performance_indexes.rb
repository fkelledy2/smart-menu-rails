class AddMissingPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # Add missing foreign key indexes
    add_index :pay_merchants, :processor_id unless index_exists?(:pay_merchants, :processor_id)
    add_index :pay_subscriptions, :payment_method_id unless index_exists?(:pay_subscriptions, :payment_method_id)
    
    # Add composite indexes for common query patterns
    # These improve performance for queries that filter by multiple columns
    
    # Orders by table and status (common in order management)
    add_index :ordrs, [:tablesetting_id, :status], 
      name: 'index_ordrs_on_tablesetting_and_status' unless index_exists?(:ordrs, [:tablesetting_id, :status])
    
    # Menu sections ordered by sequence (common in menu display)
    add_index :menusections, [:menu_id, :sequence],
      name: 'index_menusections_on_menu_and_sequence' unless index_exists?(:menusections, [:menu_id, :sequence])
  end
end

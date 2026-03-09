class AddDatabaseOptimizationIndexesPhase1 < ActiveRecord::Migration[7.2]
  def change
    # === PHASE 1: CRITICAL PERFORMANCE INDEXES ===
    # Based on DATABASE_OPTIMIZATION.md analysis
    
    # 1. ORDRITEMS - Critical for order processing performance
    add_index :ordritems, [:ordr_id, :created_at], name: 'index_ordritems_on_ordr_created_at'
    add_index :ordritems, [:menuitem_id, :status], name: 'index_ordritems_on_menuitem_status'
    add_index :ordritems, [:created_at], name: 'index_ordritems_on_created_at'
    
    # 2. EMPLOYEES - Authentication and role-based queries
    add_index :employees, [:email], name: 'index_employees_on_email'
    add_index :employees, [:restaurant_id, :created_at], name: 'index_employees_on_restaurant_created_at'
    
    # 3. MENUITEMS - Menu display and search performance
    add_index :menuitems, [:menusection_id, :status], name: 'index_menuitems_on_menusection_status'
    add_index :menuitems, [:menusection_id, :sequence], name: 'index_menuitems_on_menusection_sequence'
    add_index :menuitems, [:created_at], name: 'index_menuitems_on_created_at'
    add_index :menuitems, [:updated_at], name: 'index_menuitems_on_updated_at'
    
    # 4. MENUS - Restaurant menu queries
    add_index :menus, [:restaurant_id, :created_at], name: 'index_menus_on_restaurant_created_at'
    add_index :menus, [:restaurant_id, :updated_at], name: 'index_menus_on_restaurant_updated_at'
    
    # 5. ORDRS - Order analytics and reporting
    add_index :ordrs, [:restaurant_id, :created_at, :gross], name: 'index_ordrs_on_restaurant_created_gross'
    add_index :ordrs, [:employee_id, :created_at], name: 'index_ordrs_on_employee_created_at'
    add_index :ordrs, [:updated_at], name: 'index_ordrs_on_updated_at'
    
    # 6. TABLESETTINGS - Table management queries  
    add_index :tablesettings, [:restaurant_id, :created_at], name: 'index_tablesettings_on_restaurant_created_at'
    
    # 7. INVENTORIES - Stock management queries
    add_index :inventories, [:menuitem_id, :updated_at], name: 'index_inventories_on_menuitem_updated_at'
    # Note: inventories table doesn't have restaurant_id column
    
    # 8. ANALYTICS TABLES - Reporting performance
    add_index :metrics, [:created_at], name: 'index_metrics_on_created_at'
    # Note: metrics table doesn't have restaurant_id column
    
    # 9. LOCALIZATION - Multi-language support
    add_index :menuitemlocales, [:menuitem_id, :locale, :status], name: 'index_menuitemlocales_on_menuitem_locale_status' if column_exists?(:menuitemlocales, :status)
    add_index :menusectionlocales, [:menusection_id, :status], name: 'index_menusectionlocales_on_menusection_status' if column_exists?(:menusectionlocales, :status)
    
    # 10. CONTACTS - Customer support queries
    add_index :contacts, [:created_at], name: 'index_contacts_on_created_at'
    add_index :contacts, [:email], name: 'index_contacts_on_email'
  end
end

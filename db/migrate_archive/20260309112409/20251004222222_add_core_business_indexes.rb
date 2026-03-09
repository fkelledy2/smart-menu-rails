class AddCoreBusinessIndexes < ActiveRecord::Migration[7.1]
  def change
    # Core business logic indexes for performance optimization
    # These indexes support the most common query patterns in the application
    
    # Restaurant-level indexes (user ownership and status filtering)
    add_index :restaurants, [:user_id, :status], 
              where: "archived = false", 
              name: "index_restaurants_on_user_status_active"
    
    # Menu-level indexes (restaurant scoping and status filtering)
    add_index :menus, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_menus_on_restaurant_status_active"
    
    # Menusection-level indexes (menu scoping and sequence ordering)
    add_index :menusections, [:menu_id, :status, :sequence], 
              where: "archived = false", 
              name: "index_menusections_on_menu_status_sequence"
    
    # Menuitem-level indexes (section scoping and status filtering)
    add_index :menuitems, [:menusection_id, :status], 
              where: "archived = false", 
              name: "index_menuitems_on_section_status_active"
    
    # Order-level indexes (restaurant reporting and status tracking)
    add_index :ordrs, [:restaurant_id, :status], 
              name: "index_ordrs_on_restaurant_status"
    
    # Order items status tracking (critical for kitchen operations)
    add_index :ordritems, [:ordr_id, :status], 
              name: "index_ordritems_on_ordr_status"
    
    # Employee management (restaurant scoping)
    add_index :employees, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_employees_on_restaurant_status_active"
    
    # Table management (restaurant scoping and status)
    add_index :tablesettings, [:restaurant_id, :status], 
              where: "archived = false", 
              name: "index_tablesettings_on_restaurant_status_active"
    
    # Inventory tracking (critical for stock management)
    add_index :inventories, [:menuitem_id, :status], 
              where: "archived = false", 
              name: "index_inventories_on_menuitem_status_active"
  end
end

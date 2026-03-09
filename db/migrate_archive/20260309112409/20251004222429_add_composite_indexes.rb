class AddCompositeIndexes < ActiveRecord::Migration[7.1]
  def change
    # Composite indexes for common query patterns
    # These indexes optimize complex queries used throughout the application

    # Order analytics and reporting (restaurant + time-based queries)
    add_index :ordrs, %i[restaurant_id created_at status],
              name: 'index_ordrs_on_restaurant_created_status'

    # Table-based order lookup (for QR code scanning and table management)
    add_index :ordrs, %i[tablesetting_id status created_at],
              name: 'index_ordrs_on_table_status_created'

    # Menu availability queries (day of week and time-based filtering)
    add_index :menuavailabilities, %i[menu_id dayofweek starthour],
              where: 'archived = false',
              name: 'index_menuavailabilities_on_menu_day_time'

    # Employee role and restaurant scoping
    add_index :employees, %i[restaurant_id role status],
              where: 'archived = false',
              name: 'index_employees_on_restaurant_role_status'

    # Smart menu lookup (slug-based with restaurant context)
    add_index :smartmenus, %i[restaurant_id slug],
              name: 'index_smartmenus_on_restaurant_slug'

    # OCR import processing (restaurant + status for batch operations)
    add_index :ocr_menu_imports, %i[restaurant_id status created_at],
              name: 'index_ocr_imports_on_restaurant_status_created'

    # Menu item search and filtering (section + status + sequence for ordering)
    add_index :menuitems, %i[menusection_id status sequence],
              where: 'archived = false',
              name: 'index_menuitems_on_section_status_sequence'

    # User plan lookup (for subscription management)
    add_index :users, %i[plan_id admin],
              name: 'index_users_on_plan_admin'

    # Generated images lookup (multi-level association)
    add_index :genimages, %i[restaurant_id menu_id menuitem_id],
              name: 'index_genimages_on_restaurant_menu_item'
  end
end

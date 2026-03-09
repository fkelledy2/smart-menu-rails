# frozen_string_literal: true

class AddCounterCaches < ActiveRecord::Migration[7.2]
  def change
    # Add counter cache columns for performance optimization

    # Restaurant counter caches
    add_column :restaurants, :menus_count, :integer, default: 0
    add_column :restaurants, :employees_count, :integer, default: 0
    add_column :restaurants, :ordrs_count, :integer, default: 0
    add_column :restaurants, :tablesettings_count, :integer, default: 0
    add_column :restaurants, :ocr_menu_imports_count, :integer, default: 0

    # Menu counter caches
    add_column :menus, :menuitems_count, :integer, default: 0
    add_column :menus, :menusections_count, :integer, default: 0

    # MenuSection counter caches
    add_column :menusections, :menuitems_count, :integer, default: 0

    # Ordr counter caches
    add_column :ordrs, :ordritems_count, :integer, default: 0
    add_column :ordrs, :ordrparticipants_count, :integer, default: 0

    # MenuItem counter caches
    add_column :menuitems, :ordritems_count, :integer, default: 0

    # User counter caches
    add_column :users, :restaurants_count, :integer, default: 0
    add_column :users, :employees_count, :integer, default: 0

    # Add indexes for counter cache columns (frequently queried)
    add_index :restaurants, :menus_count
    add_index :restaurants, :employees_count
    add_index :menus, :menuitems_count
    add_index :menusections, :menuitems_count
    add_index :ordrs, :ordritems_count

    # Backfill counter cache values using raw SQL for safety
    # This avoids issues with uninitialized counter_cache associations

    # Backfill restaurants.menus_count
    execute <<~SQL
      UPDATE restaurants r
      SET menus_count = sub.count
      FROM (
        SELECT restaurant_id, COUNT(*) as count
        FROM menus
        GROUP BY restaurant_id
      ) sub
      WHERE r.id = sub.restaurant_id
    SQL

    # Backfill restaurants.employees_count
    execute <<~SQL
      UPDATE restaurants r
      SET employees_count = sub.count
      FROM (
        SELECT restaurant_id, COUNT(*) as count
        FROM employees
        GROUP BY restaurant_id
      ) sub
      WHERE r.id = sub.restaurant_id
    SQL

    # Backfill restaurants.ordrs_count
    execute <<~SQL
      UPDATE restaurants r
      SET ordrs_count = sub.count
      FROM (
        SELECT restaurant_id, COUNT(*) as count
        FROM ordrs
        GROUP BY restaurant_id
      ) sub
      WHERE r.id = sub.restaurant_id
    SQL

    # Backfill restaurants.tablesettings_count
    execute <<~SQL
      UPDATE restaurants r
      SET tablesettings_count = sub.count
      FROM (
        SELECT restaurant_id, COUNT(*) as count
        FROM tablesettings
        GROUP BY restaurant_id
      ) sub
      WHERE r.id = sub.restaurant_id
    SQL

    # Backfill restaurants.ocr_menu_imports_count
    execute <<~SQL
      UPDATE restaurants r
      SET ocr_menu_imports_count = sub.count
      FROM (
        SELECT restaurant_id, COUNT(*) as count
        FROM ocr_menu_imports
        GROUP BY restaurant_id
      ) sub
      WHERE r.id = sub.restaurant_id
    SQL

    # Backfill menus.menuitems_count (via menusections)
    execute <<~SQL
      UPDATE menus m
      SET menuitems_count = sub.count
      FROM (
        SELECT menusections.menu_id, COUNT(menuitems.id) as count
        FROM menusections
        LEFT JOIN menuitems ON menuitems.menusection_id = menusections.id
        GROUP BY menusections.menu_id
      ) sub
      WHERE m.id = sub.menu_id
    SQL

    # Backfill menus.menusections_count
    execute <<~SQL
      UPDATE menus m
      SET menusections_count = sub.count
      FROM (
        SELECT menu_id, COUNT(*) as count
        FROM menusections
        GROUP BY menu_id
      ) sub
      WHERE m.id = sub.menu_id
    SQL

    # Backfill menusections.menuitems_count
    execute <<~SQL
      UPDATE menusections ms
      SET menuitems_count = sub.count
      FROM (
        SELECT menusection_id, COUNT(*) as count
        FROM menuitems
        GROUP BY menusection_id
      ) sub
      WHERE ms.id = sub.menusection_id
    SQL

    # Backfill ordrs.ordritems_count
    execute <<~SQL
      UPDATE ordrs o
      SET ordritems_count = sub.count
      FROM (
        SELECT ordr_id, COUNT(*) as count
        FROM ordritems
        GROUP BY ordr_id
      ) sub
      WHERE o.id = sub.ordr_id
    SQL

    # Backfill ordrs.ordrparticipants_count
    execute <<~SQL
      UPDATE ordrs o
      SET ordrparticipants_count = sub.count
      FROM (
        SELECT ordr_id, COUNT(*) as count
        FROM ordrparticipants
        GROUP BY ordr_id
      ) sub
      WHERE o.id = sub.ordr_id
    SQL

    # Backfill menuitems.ordritems_count
    execute <<~SQL
      UPDATE menuitems mi
      SET ordritems_count = sub.count
      FROM (
        SELECT menuitem_id, COUNT(*) as count
        FROM ordritems
        GROUP BY menuitem_id
      ) sub
      WHERE mi.id = sub.menuitem_id
    SQL

    # Backfill users.restaurants_count
    execute <<~SQL
      UPDATE users u
      SET restaurants_count = sub.count
      FROM (
        SELECT user_id, COUNT(*) as count
        FROM restaurants
        GROUP BY user_id
      ) sub
      WHERE u.id = sub.user_id
    SQL

    # Backfill users.employees_count
    execute <<~SQL
      UPDATE users u
      SET employees_count = sub.count
      FROM (
        SELECT user_id, COUNT(*) as count
        FROM employees
        GROUP BY user_id
      ) sub
      WHERE u.id = sub.user_id
    SQL
  end
end

class AddUniqueIndexesForSmartmenus < ActiveRecord::Migration[7.1]
  def change
    # Ensure Smartmenu generator is concurrency-safe by preventing duplicates at the DB layer.

    # One "global" smartmenu per restaurant+menu (tablesetting_id NULL)
    add_index :smartmenus,
              %i[restaurant_id menu_id],
              unique: true,
              where: 'tablesetting_id IS NULL AND menu_id IS NOT NULL',
              name: 'uniq_smartmenus_restaurant_menu_global'

    # One smartmenu per restaurant+menu+tablesetting (menu_id + tablesetting_id present)
    add_index :smartmenus,
              %i[restaurant_id menu_id tablesetting_id],
              unique: true,
              where: 'menu_id IS NOT NULL AND tablesetting_id IS NOT NULL',
              name: 'uniq_smartmenus_restaurant_menu_table'

    # One "general" smartmenu per restaurant+tablesetting (menu_id NULL)
    add_index :smartmenus,
              %i[restaurant_id tablesetting_id],
              unique: true,
              where: 'menu_id IS NULL AND tablesetting_id IS NOT NULL',
              name: 'uniq_smartmenus_restaurant_table_general'
  end
end

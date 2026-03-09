class AddOwnerRestaurantIdToMenusAndBackfillRestaurantMenus < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_reference :menus, :owner_restaurant, foreign_key: { to_table: :restaurants }, index: true

    say_with_time 'Backfilling menus.owner_restaurant_id from menus.restaurant_id' do
      execute <<~SQL
        UPDATE menus
        SET owner_restaurant_id = restaurant_id
        WHERE owner_restaurant_id IS NULL
      SQL
    end

    say_with_time 'Backfilling restaurant_menus attachments for existing menus' do
      execute <<~SQL
        INSERT INTO restaurant_menus
          (restaurant_id, menu_id, sequence, status, availability_override_enabled, availability_state, created_at, updated_at)
        SELECT
          m.restaurant_id,
          m.id,
          m.sequence,
          COALESCE(m.status, 1),
          FALSE,
          0,
          NOW(),
          NOW()
        FROM menus m
        WHERE m.restaurant_id IS NOT NULL
        ON CONFLICT (restaurant_id, menu_id) DO NOTHING
      SQL
    end
  end

  def down
    remove_index :restaurant_menus, column: %i[restaurant_id menu_id] if index_exists?(:restaurant_menus, %i[restaurant_id menu_id])
    execute 'DELETE FROM restaurant_menus' if table_exists?(:restaurant_menus)

    remove_reference :menus, :owner_restaurant, foreign_key: { to_table: :restaurants }
  end
end

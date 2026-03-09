class AddSequenceToRestaurantlocales < ActiveRecord::Migration[7.1]
  def up
    add_column :restaurantlocales, :sequence, :integer

    execute <<~SQL
      UPDATE restaurantlocales rl
      SET sequence = s.rn - 1
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY restaurant_id ORDER BY id ASC) AS rn
        FROM restaurantlocales
      ) s
      WHERE rl.id = s.id;
    SQL

    change_column_null :restaurantlocales, :sequence, false
    change_column_default :restaurantlocales, :sequence, 0
    add_index :restaurantlocales, %i[restaurant_id sequence]
  end

  def down
    remove_index :restaurantlocales, column: %i[restaurant_id sequence]
    remove_column :restaurantlocales, :sequence
  end
end

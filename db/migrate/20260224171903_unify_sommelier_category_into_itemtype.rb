class UnifySommelierCategoryIntoItemtype < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  # Mapping from sommelier_category string → new itemtype integer value.
  # Existing itemtype enum: food=0, beverage=1, wine=2, spirit=3 (was "spirits")
  # New values:             beer=4, cider=5, cocktail=6, liqueur=7, whiskey=8, non_alcoholic=9, other_spirit=10
  CATEGORY_TO_ITEMTYPE = {
    'wine'          => 2,
    'spirit'        => 3,
    'beer'          => 4,
    'cider'         => 5,
    'cocktail'      => 6,
    'liqueur'       => 7,
    'whiskey'       => 8,
    'non_alcoholic' => 9,
    'other_spirit'  => 10,
    'food'          => 0,
  }.freeze

  def up
    # Phase 1: Migrate sommelier_category data into itemtype (batch update)
    unless column_exists?(:menuitems, :sommelier_category)
      say 'sommelier_category column already removed — skipping data migration'
      return
    end

    CATEGORY_TO_ITEMTYPE.each do |category, int_value|
      count = exec_update(
        "UPDATE menuitems SET itemtype = #{int_value}, updated_at = NOW() " \
        "WHERE sommelier_category = #{connection.quote(category)} " \
        "AND (itemtype IS NULL OR itemtype = 1)", # only overwrite unclassified (beverage=1) or NULL
      )
      say "  #{category} → itemtype #{int_value}: #{count} rows"
    end

    # Also map items that were itemtype=3 (old "spirits") — they keep value 3 (now "spirit")
    # No data change needed since the integer value is the same.

    # Phase 2: Remove sommelier_category column
    remove_column :menuitems, :sommelier_category, :string
  end

  def down
    # Re-add the column
    add_column :menuitems, :sommelier_category, :string unless column_exists?(:menuitems, :sommelier_category)

    # Best-effort reverse mapping from expanded itemtype back to sommelier_category
    CATEGORY_TO_ITEMTYPE.each do |category, int_value|
      next if int_value <= 1 # don't reverse food/beverage

      exec_update(
        "UPDATE menuitems SET sommelier_category = #{connection.quote(category)}, updated_at = NOW() " \
        "WHERE itemtype = #{int_value}",
      )
    end
  end

  private

  # Rails 7.2 exec_update requires a name; provide a helper that returns affected row count
  def exec_update(sql)
    connection.exec_update(sql, 'UnifySommelierCategory')
  end
end

class AddThemeToSmartmenus < ActiveRecord::Migration[7.2]
  def up
    add_column :smartmenus, :theme, :string, null: false, default: 'modern'

    execute <<~SQL
      ALTER TABLE smartmenus
        ADD CONSTRAINT smartmenus_theme_check
        CHECK (theme IN ('modern', 'rustic', 'elegant'));
    SQL
  end

  def down
    execute 'ALTER TABLE smartmenus DROP CONSTRAINT IF EXISTS smartmenus_theme_check;'
    remove_column :smartmenus, :theme
  end
end

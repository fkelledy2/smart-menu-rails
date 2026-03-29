class CreateMenuExperiments < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_experiments do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :control_version, null: false, foreign_key: { to_table: :menu_versions }
      t.references :variant_version, null: false, foreign_key: { to_table: :menu_versions }
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.integer :allocation_pct, null: false, default: 50
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_check_constraint :menu_experiments,
                         'allocation_pct >= 1 AND allocation_pct <= 99',
                         name: 'chk_menu_experiments_allocation_pct'
    add_check_constraint :menu_experiments,
                         'ends_at > starts_at',
                         name: 'chk_menu_experiments_ends_after_starts'

    add_index :menu_experiments, %i[menu_id status]
    add_index :menu_experiments, %i[menu_id starts_at ends_at]
  end
end

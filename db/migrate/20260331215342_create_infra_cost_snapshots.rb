class CreateInfraCostSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :infra_cost_snapshots do |t|
      t.date :month, null: false
      t.string :provider, null: false, default: 'heroku'
      t.string :space_name, null: false
      t.string :environment, null: false
      t.integer :estimated_monthly_cost_cents, null: false, default: 0
      t.integer :app_count, null: false, default: 0
      t.jsonb :formation_rollup_json, null: false, default: {}
      t.jsonb :addons_rollup_json, null: false, default: {}
      t.bigint :created_by_user_id
      t.bigint :updated_by_user_id

      t.timestamps
    end

    add_index :infra_cost_snapshots, %i[provider space_name environment month], unique: true,
                                                                                name: 'index_infra_cost_snapshots_unique'
    add_index :infra_cost_snapshots, :month
    add_index :infra_cost_snapshots, :environment
  end
end

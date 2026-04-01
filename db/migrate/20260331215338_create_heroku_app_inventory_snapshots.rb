class CreateHerokuAppInventorySnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :heroku_app_inventory_snapshots do |t|
      t.datetime :captured_at, null: false
      t.string :space_name, null: false
      t.string :app_id, null: false
      t.string :app_name, null: false
      t.string :pipeline_id
      t.string :pipeline_stage
      t.string :environment, null: false, default: 'unknown'
      t.jsonb :formation_json, null: false, default: {}
      t.jsonb :addons_json, null: false, default: {}

      t.timestamps
    end

    add_index :heroku_app_inventory_snapshots, %i[space_name captured_at]
    add_index :heroku_app_inventory_snapshots, %i[app_name captured_at]
    add_index :heroku_app_inventory_snapshots, :app_id
  end
end

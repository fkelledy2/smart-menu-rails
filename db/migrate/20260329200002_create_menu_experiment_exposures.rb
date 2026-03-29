class CreateMenuExperimentExposures < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_experiment_exposures do |t|
      t.references :menu_experiment, null: false, foreign_key: true
      t.references :assigned_version, null: false, foreign_key: { to_table: :menu_versions }
      t.references :dining_session, null: false, foreign_key: true
      t.datetime :exposed_at, null: false
      t.timestamps
    end

    add_index :menu_experiment_exposures, %i[menu_experiment_id assigned_version_id]
    add_index :menu_experiment_exposures,
              %i[dining_session_id menu_experiment_id],
              unique: true,
              name: 'idx_exposures_session_experiment'
  end
end

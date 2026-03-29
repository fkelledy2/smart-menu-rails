class AddExperimentFieldsToDiningSessions < ActiveRecord::Migration[7.2]
  def change
    add_reference :dining_sessions, :menu_experiment,
                  foreign_key: { to_table: :menu_experiments },
                  null: true
    add_reference :dining_sessions, :assigned_version,
                  foreign_key: { to_table: :menu_versions },
                  null: true
  end
end

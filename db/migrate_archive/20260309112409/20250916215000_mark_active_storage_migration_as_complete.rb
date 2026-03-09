class MarkActiveStorageMigrationAsComplete < ActiveRecord::Migration[7.0]
  def up
    # Mark the Active Storage migration as completed
    execute "INSERT INTO schema_migrations (version) VALUES ('20250916201742') ON CONFLICT DO NOTHING"
  end
  
  def down
    # No need to do anything on rollback
  end
end

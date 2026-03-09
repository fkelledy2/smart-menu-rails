class SkipActiveStorageMigration < ActiveRecord::Migration[7.0]
  def up
    # This migration is a no-op because Active Storage tables already exist
    # We're just using it to mark the Active Storage migration as applied
    
    # Find the migration version for the Active Storage tables
    version = 20250916201742 # The timestamp from the failing migration
    
    # Add an entry to the schema_migrations table to mark it as applied
    execute "INSERT INTO schema_migrations (version) VALUES ('#{version}') ON CONFLICT DO NOTHING"
  end
  
  def down
    # No need to do anything on rollback
  end
end

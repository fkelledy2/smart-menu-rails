class FixFlavorProfilesVectorColumn < ActiveRecord::Migration[7.2]
  def up
    remove_column :flavor_profiles, :embedding_vector if column_exists?(:flavor_profiles, :embedding_vector)
  end

  def down
    unless column_exists?(:flavor_profiles, :embedding_vector)
      execute "ALTER TABLE flavor_profiles ADD COLUMN embedding_vector vector(1024)"
    end
  end
end

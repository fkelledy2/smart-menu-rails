class AddEnabledIntegrationsToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :enabled_integrations, :jsonb, null: false, default: []
    add_index :restaurants, :enabled_integrations, using: :gin,
              name: 'index_restaurants_on_enabled_integrations'
  end
end

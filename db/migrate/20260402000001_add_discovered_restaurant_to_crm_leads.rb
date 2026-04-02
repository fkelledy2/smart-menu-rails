# frozen_string_literal: true

class AddDiscoveredRestaurantToCrmLeads < ActiveRecord::Migration[7.2]
  def change
    add_reference :crm_leads, :discovered_restaurant,
                  null: true,
                  foreign_key: true,
                  index: { unique: true, where: 'discovered_restaurant_id IS NOT NULL',
                           name: 'index_crm_leads_on_discovered_restaurant_id_partial' }
  end
end

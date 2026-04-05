# frozen_string_literal: true

class AddServiceOperationsSettingsToRestaurants < ActiveRecord::Migration[7.2]
  def change
    add_column :restaurants, :service_operations_wait_threshold_minutes, :integer, default: 25, null: false
    add_column :restaurants, :kitchen_congestion_threshold, :integer, default: 8, null: false
  end
end

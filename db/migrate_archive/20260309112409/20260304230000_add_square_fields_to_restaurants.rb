# frozen_string_literal: true

class AddSquareFieldsToRestaurants < ActiveRecord::Migration[7.2]
  def change
    # Payment provider selection (stripe or square)
    add_column :restaurants, :payment_provider, :string, default: 'stripe'

    # Provider connection status: disconnected(0), connected(10), degraded(20)
    add_column :restaurants, :payment_provider_status, :integer, default: 0, null: false

    # Square checkout mode: inline(0), hosted(10)
    add_column :restaurants, :square_checkout_mode, :integer, default: 0, null: false

    # Square-specific identifiers
    add_column :restaurants, :square_location_id, :string
    add_column :restaurants, :square_merchant_id, :string
    add_column :restaurants, :square_application_id, :string
    add_column :restaurants, :square_oauth_revoked_at, :datetime

    # Platform fee configuration
    add_column :restaurants, :platform_fee_type, :integer, default: 0, null: false
    add_column :restaurants, :platform_fee_percent, :decimal, precision: 5, scale: 2
    add_column :restaurants, :platform_fee_fixed_cents, :integer
  end
end

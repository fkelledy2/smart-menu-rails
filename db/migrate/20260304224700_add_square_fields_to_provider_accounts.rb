# frozen_string_literal: true

class AddSquareFieldsToProviderAccounts < ActiveRecord::Migration[7.2]
  def change
    # Encrypted OAuth token storage (used by Square; Stripe uses external account IDs)
    add_column :provider_accounts, :access_token_ciphertext, :text
    add_column :provider_accounts, :refresh_token_ciphertext, :text
    add_column :provider_accounts, :token_expires_at, :datetime

    # Environment scoping (production vs sandbox)
    add_column :provider_accounts, :environment, :string, default: 'production', null: false

    # OAuth scopes granted during authorization
    add_column :provider_accounts, :scopes, :text

    # Lifecycle timestamps
    add_column :provider_accounts, :connected_at, :datetime
    add_column :provider_accounts, :disconnected_at, :datetime

    # Allow provider_account_id to be nullable for Square (set after OAuth exchange)
    change_column_null :provider_accounts, :provider_account_id, true
  end
end

# frozen_string_literal: true

# Rails ActiveRecord Encryption (encrypts :access_token) expects the column
# to be named `access_token`, not `access_token_ciphertext`.
# The _ciphertext suffix is a convention from other encryption gems (Lockbox, attr_encrypted).
class RenameProviderAccountTokenColumns < ActiveRecord::Migration[7.2]
  def change
    rename_column :provider_accounts, :access_token_ciphertext, :access_token
    rename_column :provider_accounts, :refresh_token_ciphertext, :refresh_token
  end
end

# frozen_string_literal: true

# ActiveRecord Encryption configuration.
#
# Keys can be provided via:
#   1. Rails credentials (active_record_encryption.primary_key, etc.)
#   2. Environment variables (preferable for Heroku)
#
# Generate keys with: bin/rails db:encryption:init
#
# In production, set these env vars:
#   ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
#   ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
#   ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT

Rails.application.config.active_record.encryption.primary_key =
  ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'] ||
  Rails.application.credentials.dig(:active_record_encryption, :primary_key)

Rails.application.config.active_record.encryption.deterministic_key =
  ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'] ||
  Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)

Rails.application.config.active_record.encryption.key_derivation_salt =
  ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'] ||
  Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)

# During the backfill migration period, allow reading plaintext values from columns
# that now have `encrypts` declared. Remove this once all existing rows are backfilled
# via the backfill rake task (lib/tasks/encrypt_pii.rake).
Rails.application.config.active_record.encryption.support_unencrypted_data = true

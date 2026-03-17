# frozen_string_literal: true

Devise.setup do |config|
  # ==> Security Extension
  # Password expires after 90 days
  config.expire_password_after = 90.days

  # Password complexity requirements (disabled for now to avoid breaking existing users)
  # config.password_complexity = { digit: 1, lower: 1, symbol: 1, upper: 1 }

  # Keep last 5 passwords in archive
  config.password_archiving_count = 5

  # Deny reuse of last 5 passwords
  config.deny_old_passwords = 5

  # Session timeout after 30 minutes of inactivity  
  config.expire_after = 30.minutes
end

# frozen_string_literal: true

# Backfills AR Encryption for PII fields added in the 2026-03-20 security audit.
#
# Run once after deploying the `encrypts` declarations. When complete, remove
# `support_unencrypted_data = true` from config/initializers/active_record_encryption.rb.
#
# Usage:
#   bin/rails pii:encrypt              # encrypt all models
#   bin/rails pii:encrypt:users        # users only
#   bin/rails pii:encrypt:employees    # employees only
#   bin/rails pii:encrypt:payments     # payment_attempts only
#
# Safe to re-run: already-encrypted rows are skipped automatically by AR Encryption.

namespace :pii do
  namespace :encrypt do
    desc 'Backfill AR Encryption on User#first_name and User#last_name'
    task users: :environment do
      total = User.count
      puts "Encrypting #{total} users..."
      encrypted = 0

      User.find_each do |user|
        user.encrypt
        encrypted += 1
        print "\r  #{encrypted}/#{total}" if (encrypted % 100).zero?
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[pii:encrypt:users] Skipped user ##{user.id}: #{e.message}")
      end

      puts "\nDone. #{encrypted} users processed."
    end

    desc 'Backfill AR Encryption on Employee#name and Employee#email'
    task employees: :environment do
      total = Employee.count
      puts "Encrypting #{total} employees..."
      encrypted = 0

      Employee.find_each do |employee|
        employee.encrypt
        encrypted += 1
        print "\r  #{encrypted}/#{total}" if (encrypted % 100).zero?
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[pii:encrypt:employees] Skipped employee ##{employee.id}: #{e.message}")
      end

      puts "\nDone. #{encrypted} employees processed."
    end

    desc 'Backfill AR Encryption on PaymentAttempt#provider_checkout_url'
    task payments: :environment do
      scope = PaymentAttempt.where.not(provider_checkout_url: nil)
      total = scope.count
      puts "Encrypting #{total} payment attempts with a checkout URL..."
      encrypted = 0

      scope.find_each do |attempt|
        attempt.encrypt
        encrypted += 1
        print "\r  #{encrypted}/#{total}" if (encrypted % 100).zero?
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[pii:encrypt:payments] Skipped payment_attempt ##{attempt.id}: #{e.message}")
      end

      puts "\nDone. #{encrypted} payment attempts processed."
    end
  end

  desc 'Backfill AR Encryption on all PII fields (users, employees, payment_attempts)'
  task encrypt: %w[pii:encrypt:users pii:encrypt:employees pii:encrypt:payments] do
    puts 'All PII fields encrypted. Remove support_unencrypted_data from the AR Encryption initializer.'
  end
end

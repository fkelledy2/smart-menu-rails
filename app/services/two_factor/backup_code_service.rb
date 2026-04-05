# frozen_string_literal: true

module TwoFactor
  # Generates, hashes, stores, and validates single-use backup codes.
  class BackupCodeService
    CODE_COUNT = 10
    CODE_LENGTH = 10

    def initialize(user)
      @user = user
    end

    # Generates 10 new plaintext backup codes, hashes them with bcrypt, stores
    # the hashes in user.otp_backup_codes, and returns the plaintext codes
    # (shown once to the user).
    def generate!
      plaintext_codes = CODE_COUNT.times.map { SecureRandom.alphanumeric(CODE_LENGTH) }
      hashed = plaintext_codes.map { |code| BCrypt::Password.create(code) }
      user.update!(otp_backup_codes: hashed.to_json)
      plaintext_codes
    end

    # Returns true and consumes the code if it matches one of the stored hashes.
    # Returns false otherwise.
    def consume!(code)
      return false if user.otp_backup_codes.blank?

      hashes = JSON.parse(user.otp_backup_codes)
      matched_index = hashes.index { |h| BCrypt::Password.new(h) == code.to_s.strip }
      return false if matched_index.nil?

      hashes.delete_at(matched_index)
      user.update_columns(otp_backup_codes: hashes.to_json) # rubocop:disable Rails/SkipsModelValidations
      true
    rescue JSON::ParserError, BCrypt::Errors::InvalidHash
      false
    end

    # Returns how many backup codes remain (does not expose which ones).
    def remaining_count
      return 0 if user.otp_backup_codes.blank?

      JSON.parse(user.otp_backup_codes).length
    rescue JSON::ParserError
      0
    end

    private

    attr_reader :user
  end
end

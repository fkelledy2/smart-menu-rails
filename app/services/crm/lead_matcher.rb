# frozen_string_literal: true

module Crm
  # Deduplication lookup — pure query object, no writes.
  # Returns the first matching CrmLead or nil, evaluated in priority order:
  #   1. Exact contact_email match (case-insensitive)
  #   2. Exact contact_phone match (when submission phone is present)
  #   3. Exact restaurant_name + contact_name match (normalised downcase strip)
  #   4. No match → nil
  class LeadMatcher
    DISPOSABLE_DOMAINS = %w[
      mailinator.com
      guerrillamail.com
      throwam.com
      yopmail.com
      sharklasers.com
      guerrillamailblock.com
      grr.la
      spam4.me
      trashmail.com
      dispostable.com
    ].freeze

    # @param name [String, nil]
    # @param email [String, nil]
    # @param phone [String, nil]
    # @param restaurant_name [String, nil]
    # @return [CrmLead, nil]
    def self.call(name: nil, email: nil, phone: nil, restaurant_name: nil)
      new(name: name, email: email, phone: phone, restaurant_name: restaurant_name).call
    end

    def initialize(name:, email:, phone:, restaurant_name:)
      @name            = name&.strip&.downcase
      @email           = email&.strip&.downcase
      @phone           = phone&.strip&.presence
      @restaurant_name = restaurant_name&.strip&.downcase&.presence
    end

    # Returns true when the email domain is in the known disposable-address list
    def spam?
      return false if @email.blank?

      domain = @email.split('@').last.to_s.downcase
      DISPOSABLE_DOMAINS.include?(domain)
    end

    def call
      return nil if @email.blank? && @phone.blank? && @restaurant_name.blank?

      # Priority 1: email
      if @email.present?
        lead = CrmLead.where('LOWER(contact_email) = ?', @email).first
        return lead if lead
      end

      # Priority 2: phone
      if @phone.present?
        lead = CrmLead.where(contact_phone: @phone).first
        return lead if lead
      end

      # Priority 3: restaurant_name + contact_name
      if @restaurant_name.present? && @name.present?
        lead = CrmLead
          .where('LOWER(TRIM(restaurant_name)) = ?', @restaurant_name)
          .where('LOWER(TRIM(contact_name)) = ?', @name)
          .first
        return lead if lead
      end

      nil
    end
  end
end

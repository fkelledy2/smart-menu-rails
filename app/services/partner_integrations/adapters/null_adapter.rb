# frozen_string_literal: true

module PartnerIntegrations
  module Adapters
    # No-op adapter used in tests and as a safe default.
    # Also demonstrates the minimal interface every real adapter must satisfy.
    class NullAdapter < PartnerIntegrations::Adapter
      def self.adapter_type
        'null'
      end

      def call(event:)
        Rails.logger.debug { "[PartnerIntegrations::NullAdapter] event=#{event.event_type} restaurant=#{event.restaurant_id}" }
        true
      end
    end
  end
end

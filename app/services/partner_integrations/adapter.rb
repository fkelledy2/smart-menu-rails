# frozen_string_literal: true

module PartnerIntegrations
  # Base adapter class. Each integration type subclasses this and implements
  # `call(event:)`. The base class handles dead-letter logging on unhandled errors.
  #
  # Convention: concrete adapters live at
  #   app/services/partner_integrations/adapters/<type>_adapter.rb
  # and are named e.g. `PartnerIntegrations::Adapters::WorkforceAdapter`.
  class Adapter
    # Adapter type identifier — override in subclasses.
    # Must match a value that can appear in restaurant.enabled_integrations.
    def self.adapter_type
      raise NotImplementedError, "#{name}#adapter_type must be implemented"
    end

    # Entry point called by PartnerIntegrationDispatchJob.
    # Subclasses must implement this and raise on unrecoverable errors so the job
    # can handle retries and dead-letter logging correctly.
    def call(event:)
      raise NotImplementedError, "#{self.class.name}#call(event:) must be implemented"
    end
  end
end

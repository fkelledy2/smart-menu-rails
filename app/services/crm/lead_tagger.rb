# frozen_string_literal: true

module Crm
  # Applies one or more tags to a CrmLead idempotently.
  # Uses find_or_create_by so retrying always produces the same result.
  class LeadTagger
    # @param crm_lead [CrmLead]
    # @param tags [Array<String>] values from CrmLeadTag::VALID_TAGS
    # @return [Array<CrmLeadTag>]
    def self.call(crm_lead:, tags:)
      new(crm_lead: crm_lead, tags: tags).call
    end

    def initialize(crm_lead:, tags:)
      @crm_lead = crm_lead
      @tags     = Array(tags).map(&:to_s).select { |t| CrmLeadTag::VALID_TAGS.include?(t) }
    end

    def call
      @tags.map do |tag|
        @crm_lead.crm_lead_tags.find_or_create_by!(tag: tag)
      end
    end
  end
end

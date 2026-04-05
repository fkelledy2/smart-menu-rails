# frozen_string_literal: true

module Crm
  # Creates a CrmLead from a WebsiteContactSubmission.
  # Sets source = 'website_inbound'. Never overwrites a higher-ranked source
  # on an existing lead (this service only creates NEW leads).
  class LeadCreatorFromWebsiteSubmission
    Result = Struct.new(:success?, :lead, :error, keyword_init: true)

    # @param submission [WebsiteContactSubmission]
    # @return [Result]
    def self.call(submission:)
      new(submission: submission).call
    end

    def initialize(submission:)
      @submission = submission
    end

    def call
      lead = CrmLead.new(
        restaurant_name: @submission.restaurant_name.presence ||
                         @submission.company_name.presence ||
                         @submission.name,
        contact_name:    @submission.name,
        contact_email:   @submission.email,
        contact_phone:   @submission.phone,
        source:          'website_inbound',
        stage:           'new',
        last_activity_at: @submission.submitted_at,
      )

      if lead.save
        Result.new(success?: true, lead: lead, error: nil)
      else
        Result.new(success?: false, lead: nil, error: lead.errors.full_messages.join(', '))
      end
    end
  end
end

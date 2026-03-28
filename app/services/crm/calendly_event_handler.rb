# frozen_string_literal: true

module Crm
  # Parses a verified Calendly webhook payload and advances the matching
  # CrmLead to demo_booked. If no lead exists for the invitee email,
  # auto-creates one with source: 'calendly'. Idempotent via calendly_event_uuid.
  class CalendlyEventHandler
    Result = Struct.new(:success?, :lead, :created, :error, keyword_init: true)

    def self.call(payload:)
      new(payload: payload).call
    end

    def initialize(payload:)
      @payload = payload.is_a?(String) ? JSON.parse(payload) : payload
    end

    def call
      event_uuid = extract_event_uuid
      invitee_email = extract_invitee_email
      invitee_name = extract_invitee_name

      if invitee_email.blank?
        Rails.logger.warn('[Crm::CalendlyEventHandler] Webhook payload missing invitee email — skipping')
        return Result.new(success?: false, lead: nil, created: false, error: 'missing_invitee_email')
      end

      # Idempotency check — already processed this event
      if event_uuid.present?
        existing = CrmLead.find_by(calendly_event_uuid: event_uuid)
        return Result.new(success?: true, lead: existing, created: false, error: nil) if existing
      end

      lead, was_created = find_or_create_lead(invitee_email, invitee_name)

      # Record the Calendly event UUID so we can detect replays.
      # Rescue RecordNotUnique in case a concurrent Sidekiq retry already claimed
      # this UUID between the idempotency check above and this write.
      if event_uuid.present?
        begin
          lead.update!(calendly_event_uuid: event_uuid)
        rescue ActiveRecord::RecordNotUnique
          existing = CrmLead.find_by(calendly_event_uuid: event_uuid)
          return Result.new(success?: true, lead: existing, created: false, error: nil)
        end
      end

      # Advance stage only if not already at or past demo_booked
      past_stages = %w[demo_booked demo_completed proposal_sent trial_active converted]
      unless past_stages.include?(lead.stage)
        result = Crm::LeadTransitionService.call(
          lead: lead,
          new_stage: 'demo_booked',
          actor: nil,
        )

        unless result.success?
          return Result.new(success?: false, lead: lead, created: was_created, error: result.error)
        end
      end

      if was_created
        Crm::LeadAuditWriter.write(
          crm_lead: lead,
          event: 'stage_changed',
          actor: nil,
          actor_type: 'system',
          field_name: 'calendly_event_uuid',
          to_value: event_uuid,
          metadata: { source: 'calendly_webhook', event_uuid: event_uuid },
        )
      end

      Result.new(success?: true, lead: lead, created: was_created, error: nil)
    rescue StandardError => e
      Rails.logger.error("[Crm::CalendlyEventHandler] Error: #{e.message}")
      Result.new(success?: false, lead: nil, created: false, error: e.message)
    end

    private

    def extract_event_uuid
      @payload.dig('payload', 'event', 'uuid') ||
        @payload.dig('event', 'uuid') ||
        @payload['uuid']
    end

    def extract_invitee_email
      @payload.dig('payload', 'invitee', 'email') ||
        @payload.dig('invitee', 'email')
    end

    def extract_invitee_name
      @payload.dig('payload', 'invitee', 'name') ||
        @payload.dig('invitee', 'name')
    end

    def find_or_create_lead(email, name)
      return [CrmLead.new, true] if email.blank?

      lead = CrmLead.where('LOWER(contact_email) = ?', email.downcase).first

      if lead
        [lead, false]
      else
        new_lead = CrmLead.create!(
          restaurant_name: name.presence || 'Unknown (Calendly)',
          contact_email: email,
          contact_name: name,
          source: 'calendly',
          assigned_to_id: nil,
          stage: 'new',
          last_activity_at: Time.current,
        )

        Crm::LeadAuditWriter.write(
          crm_lead: new_lead,
          event: 'lead_created',
          actor: nil,
          actor_type: 'system',
          metadata: { source: 'calendly_webhook' },
        )

        [new_lead, true]
      end
    end
  end
end

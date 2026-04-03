# frozen_string_literal: true

module Crm
  # Validates and executes CrmLead stage transitions.
  # Writes a CrmLeadAudit record on every successful transition.
  # Enforces stage-specific preconditions.
  class LeadTransitionService
    # Valid forward transitions. 'lost' can also transition back to 'contacted'.
    FORWARD_TRANSITIONS = {
      'new' => %w[contacted demo_booked lost],
      'contacted' => %w[demo_booked proposal_sent lost],
      'demo_booked' => %w[demo_completed contacted lost],
      'demo_completed' => %w[proposal_sent contacted lost],
      'proposal_sent' => %w[trial_active contacted lost],
      'trial_active' => %w[converted contacted lost],
      'converted' => [],
      'lost' => %w[contacted],
    }.freeze

    Result = Struct.new(:success?, :lead, :error, keyword_init: true)

    # @param lead [CrmLead]
    # @param new_stage [String]
    # @param actor [User, nil]
    # @param lost_reason [String, nil] required when transitioning to 'lost'
    # @param lost_reason_notes [String, nil]
    # @param restaurant_id [Integer, nil] required when transitioning to 'converted'
    # @return [Result]
    def self.call(lead:, new_stage:, actor: nil, lost_reason: nil, lost_reason_notes: nil, restaurant_id: nil)
      new(
        lead: lead,
        new_stage: new_stage,
        actor: actor,
        lost_reason: lost_reason,
        lost_reason_notes: lost_reason_notes,
        restaurant_id: restaurant_id,
      ).call
    end

    def initialize(lead:, new_stage:, actor:, lost_reason:, lost_reason_notes:, restaurant_id:)
      @lead               = lead
      @new_stage          = new_stage.to_s
      @actor              = actor
      @lost_reason        = lost_reason
      @lost_reason_notes  = lost_reason_notes
      @restaurant_id      = restaurant_id
    end

    def call
      # Idempotent: already in target stage — succeed immediately without writing audit
      return Result.new(success?: true, lead: @lead, error: nil) if @lead.stage == @new_stage

      validate_transition!
      validate_preconditions!
      execute_transition
    rescue TransitionError => e
      Result.new(success?: false, lead: @lead, error: e.message)
    end

    private

    def validate_transition!
      allowed = FORWARD_TRANSITIONS.fetch(@lead.stage, [])
      return if allowed.include?(@new_stage)

      raise TransitionError,
            "Cannot transition from '#{@lead.stage}' to '#{@new_stage}'"
    end

    def validate_preconditions!
      if @new_stage == 'converted' && @restaurant_id.blank?
        raise TransitionError, 'A restaurant must be linked before marking a lead as converted'
      end

      if @new_stage == 'lost' && @lost_reason.blank?
        raise TransitionError, 'A lost reason is required when marking a lead as lost'
      end

      if @new_stage == 'demo_completed' && @lead.assigned_to_id.blank?
        raise TransitionError, 'A lead must be assigned before marking the demo as completed'
      end
    end

    def execute_transition
      prev_stage = @lead.stage

      @lead.assign_attributes(stage: @new_stage, last_activity_at: Time.current)

      if @new_stage == 'lost'
        @lead.lost_at = Time.current
        @lead.lost_reason = @lost_reason
        @lead.lost_reason_notes = @lost_reason_notes
      end

      if @new_stage == 'converted'
        @lead.restaurant_id = @restaurant_id
        @lead.converted_at = Time.current
      end

      # Re-opening a lost lead clears loss fields
      if @new_stage == 'contacted' && prev_stage == 'lost'
        @lead.lost_at = nil
        @lead.lost_reason = nil
        @lead.lost_reason_notes = nil
      end

      @lead.save!

      Crm::LeadAuditWriter.write(
        crm_lead: @lead,
        event: 'stage_changed',
        actor: @actor,
        actor_type: @actor ? 'user' : 'system',
        field_name: 'stage',
        from_value: prev_stage,
        to_value: @new_stage,
      )

      Result.new(success?: true, lead: @lead, error: nil)
    end

    class TransitionError < StandardError; end
  end
end

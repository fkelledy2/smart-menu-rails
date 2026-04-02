# frozen_string_literal: true

module Agents
  # Agents::PolicyEvaluator checks whether an agent action can proceed automatically
  # or needs human approval, or is blocked entirely.
  #
  # Resolution order:
  #   1. Restaurant-scoped AgentPolicy for the action_type
  #   2. Global AgentPolicy (restaurant_id IS NULL) for the action_type
  #   3. Built-in conservative default (:require_approval)
  class PolicyEvaluator
    RESULTS = %i[auto_approve require_approval blocked].freeze

    def self.call(action_type:, restaurant_id:, proposed_payload: {})
      new(action_type: action_type, restaurant_id: restaurant_id, proposed_payload: proposed_payload).call
    end

    def initialize(action_type:, restaurant_id:, proposed_payload: {})
      @action_type      = action_type.to_s
      @restaurant_id    = restaurant_id
      @proposed_payload = proposed_payload
    end

    # @return [:auto_approve, :require_approval, :blocked]
    def call
      policy = find_policy
      return :require_approval unless policy
      return :require_approval unless policy.active?
      return :auto_approve if policy.auto_approve?

      :require_approval
    end

    private

    def find_policy
      # Restaurant-scoped policy takes precedence over global default.
      AgentPolicy.active
        .where(action_type: @action_type)
        .where('restaurant_id = ? OR restaurant_id IS NULL', @restaurant_id)
        .order(Arel.sql('restaurant_id IS NULL ASC'))
        .first
    end
  end
end

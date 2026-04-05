# frozen_string_literal: true

module Agents
  # Raised when an agent tool attempts a write-action without a confirmed AgentApproval.
  # This is the safety guard for autonomous mutation prevention.
  class UnauthorisedActionError < StandardError
    def initialize(msg = 'Agent tool action requires explicit staff confirmation via AgentApproval')
      super
    end
  end
end

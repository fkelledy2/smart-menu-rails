# frozen_string_literal: true

module Agents
  # Agents::Dispatcher receives a domain event payload, looks up the registered
  # workflow type, checks the Flipper flag, and enqueues the correct job.
  # Idempotent: duplicate events for the same run do not enqueue a second job.
  class Dispatcher
    # Registry mapping event_type strings to workflow types.
    # Individual agents register themselves here via .register.
    WORKFLOW_REGISTRY = {}.freeze

    class << self
      def registry
        @registry ||= {}
      end

      # Register an event_type → workflow_type mapping.
      # @param event_type    [String] e.g. 'order.completed'
      # @param workflow_type [String] e.g. 'menu_import'
      def register(event_type, workflow_type:)
        registry[event_type.to_s] = workflow_type.to_s
      end

      def call(domain_event)
        new(domain_event).call
      end
    end

    def initialize(domain_event)
      @domain_event = domain_event
    end

    # @return [:enqueued, :skipped_flag, :skipped_no_workflow, :skipped_duplicate]
    def call
      return :skipped_no_workflow unless workflow_type

      restaurant_id = @domain_event.payload['restaurant_id']
      return :skipped_no_workflow unless restaurant_id

      restaurant = Restaurant.find_by(id: restaurant_id)
      return :skipped_no_workflow unless restaurant

      unless Flipper.enabled?(:agent_framework, restaurant)
        Rails.logger.info("[Agents::Dispatcher] agent_framework flag disabled for restaurant #{restaurant_id}")
        return :skipped_flag
      end

      if existing_run_pending?(restaurant_id)
        Rails.logger.info("[Agents::Dispatcher] Skipping duplicate dispatch for event #{@domain_event.id}")
        return :skipped_duplicate
      end

      run = create_workflow_run!(restaurant, workflow_type)
      Agents::DispatchDomainEventJob.perform_later(run.id)

      Rails.logger.info("[Agents::Dispatcher] Enqueued workflow run #{run.id} for #{workflow_type}")
      :enqueued
    end

    private

    def workflow_type
      self.class.registry[@domain_event.event_type]
    end

    def existing_run_pending?(restaurant_id)
      AgentWorkflowRun
        .for_restaurant(restaurant_id)
        .where(workflow_type: workflow_type, trigger_event: @domain_event.event_type)
        .active
        .exists?
    end

    def create_workflow_run!(restaurant, type)
      AgentWorkflowRun.create!(
        restaurant: restaurant,
        workflow_type: type,
        trigger_event: @domain_event.event_type,
        status: 'pending',
        context_snapshot: @domain_event.payload,
      )
    end
  end
end

# frozen_string_literal: true

# Register all agent workflow → event_type mappings with the Dispatcher.
# Each workflow registers the domain events it handles and optionally its dedicated job class.
Rails.application.config.after_initialize do
  # Menu Import Agent — triggered when a new OcrMenuImport is created
  Agents::Dispatcher.register(
    'menu.import.requested',
    workflow_type: 'menu_import',
    job_class: Agents::MenuImportWorkflowJob,
  )

  # Restaurant Growth Agent — triggered by weekly scheduler or on-demand button
  Agents::Dispatcher.register(
    'manager_digest.scheduled',
    workflow_type: 'growth_digest',
    job_class: Agents::ManagerDigestWorkflowJob,
  )

  # Menu Optimization Agent — triggered by nightly scheduler or on-demand button
  Agents::Dispatcher.register(
    'menu_optimization.scheduled',
    workflow_type: 'menu_optimization',
    job_class: Agents::MenuOptimizationWorkflowJob,
  )
  Agents::Dispatcher.register(
    'menu_optimization.requested',
    workflow_type: 'menu_optimization',
    job_class: Agents::MenuOptimizationWorkflowJob,
  )

  # Service Operations Agent — triggered by kitchen heartbeat and inventory/order events
  Agents::Dispatcher.register(
    'kitchen.queue_check',
    workflow_type: 'service_operations',
    job_class: Agents::ServiceOperationsWorkflowJob,
  )
  Agents::Dispatcher.register(
    'inventory.low',
    workflow_type: 'service_operations',
    job_class: Agents::ServiceOperationsWorkflowJob,
  )
  Agents::Dispatcher.register(
    'order.submitted',
    workflow_type: 'service_operations',
    job_class: Agents::ServiceOperationsWorkflowJob,
  )
end

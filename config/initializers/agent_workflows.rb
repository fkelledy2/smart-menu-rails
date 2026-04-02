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
end

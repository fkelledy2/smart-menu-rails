---
name: Menu Import Agent v1 implementation decisions
description: Menu Import Agent #18 architecture, key patterns, and gotchas (April 2026)
type: project
---

Menu Import Agent (#18) shipped April 2026. 8-step pipeline: fetch_source → read_context → extract_structure → normalise_and_tag → policy_validate → write_draft → queue_enrichment → notify_manager.

**Why:** Reduces time-to-first-menu from hours to minutes during restaurant onboarding.
**How to apply:** When touching agent workflows or OCR imports, be aware of these decisions.

## Architecture decisions

- **Workflow class** is `Agents::Workflows::MenuImportWorkflow` in `app/services/agents/workflows/`. Does NOT use generic `Agents::Runner` — it has its own step orchestration because the steps require LLM calls in a specific sequence, not tool-call dispatch.
- **Dispatcher extension**: Added `job_class:` optional kwarg to `Agents::Dispatcher.register`. New job_registry maps `workflow_type → job_class`. If no job_class registered, falls back to `DispatchDomainEventJob`. Registration happens in `config/initializers/agent_workflows.rb`.
- **Domain event**: `OcrMenuImport` emits `menu.import.requested` via `after_create` callback using `AgentDomainEvent.publish!` with idempotency key `menu.import.requested:ocr_menu_import:<id>`.
- **Allergen non-negotiable**: Any item with allergens ALWAYS gets `require_approval` regardless of confidence score. This is enforced in `step_policy_validate` and `MenuImportPublisher#confirm_approved_items!`.
- **Confidence threshold**: 0.8 for auto-approval. Items below 0.8 require manual approval.
- **Publisher pattern**: `Agents::MenuImportPublisher` is the ONLY service that transitions from agent output to live menu data. It calls `confirm_approved_items!` (updates `is_confirmed` on OcrMenuItems) then delegates to existing `ImportToMenu` service.
- **New DB columns**: `ocr_menu_imports` gets `agent_workflow_run_id`, `confidence_score`, `agent_status`; `ocr_menu_items` gets `confidence_score`, `agent_approval_status`, `proposed_tags`.
- **Flipper flags**: `agent_framework` (master) + `agent_menu_import` (per-restaurant). Both must be enabled.

## Gotchas

- `Restaurant#currency_symbol` does NOT exist on the model — views must use `@restaurant.try(:currency)` or similar.
- `persist_normalised_items!` uses string escaping with `.gsub("'", "''")` inline in an ORDER clause — acceptable for section name matching but not ideal; future refactor should use parameterized approach.
- The workflow is registered via `config/initializers/agent_workflows.rb` which runs `after_initialize`. Tests that need the registration must either rely on the initializer running or manually call `Agents::Dispatcher.register(...)`.
- Step output is stored in `AgentWorkflowStep#output_snapshot` (JSONB). When reading in subsequent steps, use string keys (not symbol keys) since JSONB round-trips produce string keys.

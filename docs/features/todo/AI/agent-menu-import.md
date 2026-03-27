# Menu Import Agent

## Status
- Priority Rank: #17 (first individual agent to ship after framework)
- Category: Post-Launch — agent tier, Phase 1
- Effort: M
- Dependencies: Agent Framework (#16), existing `OcrMenuImport` / OCR infrastructure, DeepL integration, OpenAI API

## Problem Statement
Restaurant onboarding is the most friction-heavy part of the mellow.menu experience. Owners must manually recreate their existing menu — transcribing items, prices, allergens, and descriptions from PDFs, photos, and printed menus. This is time-consuming, error-prone, and is a leading cause of onboarding abandonment. An existing OCR import pipeline (`OcrMenuImport`, `PdfMenuExtractionJob`, `AiMenuPolisherJob`) partially addresses this, but it produces raw extracted text that still requires significant human cleanup. The Menu Import Agent closes this gap by applying multi-step LLM reasoning to produce a clean, structured, publishable draft menu from unstructured source material — reducing the time from first upload to publishable menu from hours to minutes.

## Success Criteria
- A restaurant owner uploads a PDF, image, or URL and receives a structured draft menu for review within 5 minutes.
- At least 85% of menu items are correctly normalised (correct name, price, section assignment) without manual correction, as measured across the first 20 onboardings.
- Allergen suggestions that require approval are never auto-applied to a live menu without explicit manager sign-off.
- The manager review UI shows a clear diff of proposed vs. existing menu items and allows per-item approve, reject, or edit.
- The agent run is fully audited: every step, tool call, and artifact is visible in the AI Workbench.

## User Stories
- As a restaurant owner, I want to upload my existing menu PDF and receive a structured draft I can approve and publish, so I can onboard without manually re-entering every item.
- As a restaurant manager, I want to review AI-proposed menu items with confidence scores before they go live, so I can catch errors before my customers see them.
- As a restaurant owner, I want allergen information to always require my explicit approval, so I am never liable for an AI hallucination on a safety-critical field.
- As a developer, I want the import agent to extend the existing `OcrMenuImport` model rather than creating a parallel pipeline, so there is one import pathway.

## Functional Requirements

1. The agent is triggered by the `menu.import.requested` domain event, emitted when an `OcrMenuImport` record is created (existing behaviour extended).
2. `Agents::Dispatcher` maps `menu.import.requested` to `Agents::MenuImportWorkflowJob` on the `agent_high` Sidekiq queue.
3. The workflow pipeline consists of the following steps, each persisted as an `AgentWorkflowStep`:
   - **Step 1: fetch_source** — download PDF/image bytes or scrape URL content using existing `PdfMenuProcessor` / `WebMenuProcessor` services. Output: raw text and any existing OCR results.
   - **Step 2: read_context** — read the restaurant's existing menus, currency, language, establishment type, and any previously imported sections using `read_restaurant_context` tool.
   - **Step 3: extract_structure** — call OpenAI Responses API with the raw text and restaurant context. Agent identifies sections, items, prices, allergens, variants, and wine/drink sizes. Output: structured JSON array of proposed sections and items.
   - **Step 4: normalise_and_tag** — second LLM pass to normalise messy text (OCR noise, inconsistent formatting), assign tags (`vegan`, `gluten-free`, `spicy`, `premium`, `kids`, `high-margin`), score confidence per item (0.0–1.0), and flag ambiguities.
   - **Step 5: policy_validate** — `Agents::PolicyEvaluator` checks each proposed item against restaurant's `AgentPolicy`. Items with allergen claims or price values below a confidence threshold of 0.8 are flagged as `require_approval`. All others are `auto_approve`.
   - **Step 6: write_draft** — `Agents::ArtifactWriter` writes the normalised item set as an `AgentArtifact` with type `menu_import_draft` and status `draft`. Existing `OcrMenuImport` record is updated with a reference to the artifact.
   - **Step 7: queue_enrichment** — for items with no image, `generate_menu_image_prompt` tool queues `MenuItemImageGeneratorJob`. For items in a non-default language, `write_draft_translation` tool enqueues `MenuLocalizationJob`.
   - **Step 8: notify_manager** — `Agents::ApprovalRouter` creates `AgentApproval` records for all `require_approval` items and sends approval email via `AgentApprovalMailer`.
4. The draft artifact uses the existing `OcrMenuSection` / `OcrMenuItem` structure plus a new `confidence_score` and `approval_status` field per item — no new data model required for the draft itself.
5. Manager review UI in the AI Workbench (`/restaurants/:id/agent_workbench`) shows a diff view: left column is the existing live menu (or empty for new restaurants), right column is the proposed draft. Each item shows: proposed name, price, allergens, tags, confidence score, and approval status.
6. Per-item actions: **Approve** (moves item to `AgentApproval` status `approved`), **Reject** (marks it `rejected` and removes from import), **Edit** (opens inline edit that creates a revised `AgentArtifact` for that item). **Bulk approve** is available for all items above confidence threshold.
7. Once all required approvals are resolved, the manager can trigger **Publish** — this calls `ImportToMenu` service (existing) to promote the approved draft to live `Menuitem` records.
8. The agent never writes directly to `Menuitem` — all writes go through the existing `ImportToMenu` service after explicit approval.

## Non-Functional Requirements
- Total pipeline time from upload to draft-ready notification: under 5 minutes for a typical 50-item menu.
- LLM calls are made in background Sidekiq jobs — never in the web request path.
- Confidence scoring must be deterministic given the same input (use temperature 0 for structure extraction steps).
- Allergen fields are treated as high-risk and always require human approval, regardless of confidence score. This is non-negotiable.
- The agent must degrade gracefully if the OpenAI API is unavailable — log the failure, set the step to `failed`, and notify the manager that manual import is needed.
- Flipper flag `agent_menu_import` must be enabled per restaurant.

## Technical Notes

### Services to Create (`app/services/agents/workflows/`)
- `agents/workflows/menu_import_workflow.rb` — orchestrates the 8-step pipeline via `Agents::Runner`

### Services to Extend
- `openai_client.rb` — add Responses API / tool-calling support (shared with Agent Framework)
- `import_to_menu.rb` — add support for accepting an approved `AgentArtifact` as input source (currently only accepts `OcrMenuImport`)

### Jobs to Create (`app/jobs/agents/`)
- `agents/menu_import_workflow_job.rb` — receives `ocr_menu_import_id`, creates/resumes `AgentWorkflowRun`, delegates to `Agents::Runner`

### Models to Extend (no new tables needed for draft)
- `OcrMenuImport` — add `agent_workflow_run_id` FK (nullable), `confidence_score` (float), `agent_status` (string: pending / processing / awaiting_approval / published / failed)
- `OcrMenuItem` — add `confidence_score` (float), `agent_approval_status` (string), `proposed_tags` (jsonb)

### Domain Event Emitter
- Extend `OcrMenuImport` after_create callback (or controller action) to write a `AgentDomainEvent` record with type `menu.import.requested`

### Flipper Flags
- `agent_framework` — master switch (required)
- `agent_menu_import` — per-restaurant enablement for this specific agent

### Tools Used (from Toolbox)
- `fetch_menu_source` — wraps existing `PdfMenuProcessor` / `WebMenuProcessor`
- `read_restaurant_context`
- `propose_menu_patch` → writes to `AgentArtifact` via `ArtifactWriter`
- `write_draft_translation` — enqueues `MenuLocalizationJob`
- `generate_menu_image_prompt` — enqueues `MenuItemImageGeneratorJob`
- `create_review_queue_task` — creates `AgentApproval` and routes to manager

### Existing Code to Integrate (do not duplicate)
- `OcrMenuImport`, `OcrMenuSection`, `OcrMenuItem` models — extend, do not replace
- `PdfMenuExtractionJob` / `AiMenuPolisherJob` — integrate into step 1/2 rather than running separately
- Google Cloud Vision OCR — already integrated; use `OcrMenuImport`'s existing OCR output as input to step 3
- `MenuLocalizationJob` — enqueue from step 7
- `MenuItemImageGeneratorJob` — enqueue from step 7

## Acceptance Criteria
1. Uploading a PDF menu creates an `OcrMenuImport`, emits a `AgentDomainEvent` with type `menu.import.requested`, and enqueues `Agents::MenuImportWorkflowJob`.
2. The workflow creates an `AgentWorkflowRun` with 8 `AgentWorkflowStep` records before any LLM call is made.
3. On completion of step 4, every proposed item has a `confidence_score` between 0.0 and 1.0.
4. Any proposed item with an allergen claim has an `AgentApproval` record with status `pending` and `require_approval` policy — even if confidence is 1.0.
5. Any proposed item with a price and confidence >= 0.8 and no allergen claim has an `AgentApproval` record with status `auto_approved`.
6. After step 8, the restaurant owner receives an email with a link to the workbench approval screen.
7. A manager approving all pending items and clicking Publish results in new `Menuitem` records created via `ImportToMenu` service. No direct SQL inserts from the agent.
8. Killing the Sidekiq worker after step 3 completes and re-running the job resumes from step 4 — step 3 is not re-executed.
9. The `Agents::ArtifactWriter` raises an error if called with a target of a live `Menuitem` record — it only writes to `AgentArtifact`.
10. With `agent_menu_import` Flipper flag disabled for a restaurant, the `AgentDomainEvent` is created but `Agents::Dispatcher` does not enqueue the workflow job.

## Out of Scope
- Real-time streaming of extraction progress to the owner's browser (post-launch polish).
- Automatic re-import when the restaurant's source website menu changes (that is the Menu Source Change Detector's remit).
- Automatic publishing without manager approval — always requires human sign-off.
- OCR improvements to the underlying Vision API integration (separate infrastructure concern).

## Open Questions
1. Should the agent attempt to map imported items to existing menu items (deduplication) or always treat an import as additive? Recommendation: flag likely duplicates with a warning but let the manager decide. Needs product confirmation.
2. Is `ImportToMenu` the correct promotion path, or should the agent write directly to `Menuitem` through the standard controller/service path? Recommendation: use `ImportToMenu` to maintain a single promotion pathway — but confirm this service handles the full item structure including allergens, tags, and sizes.
3. Should confidence thresholds be configurable per restaurant or global? Recommendation: global defaults with admin-override per restaurant in v2.

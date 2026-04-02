# Menu Import Agent (#18) — User Guide

## What It Does

The Menu Import Agent uses AI to dramatically speed up restaurant onboarding. Instead of manually re-entering every menu item from a PDF or printed menu, the agent:

1. Reads the raw OCR-extracted text from your existing PDF import pipeline.
2. Uses GPT-4o to identify sections, items, prices, and allergens.
3. Normalises OCR noise, assigns dietary tags, and scores confidence per item.
4. Flags any item with an allergen claim or low confidence for mandatory manager review.
5. Presents you with a diff-style review screen before anything goes live.
6. Publishes approved items to your live menu via the existing import pipeline.

---

## Prerequisites

1. The `agent_framework` Flipper flag must be enabled for the restaurant.
2. The `agent_menu_import` Flipper flag must be enabled for the restaurant.
3. The restaurant must have a valid OpenAI API key configured (`OPENAI_API_KEY` environment variable or credentials).

**Enable for a restaurant (Rails console):**
```ruby
restaurant = Restaurant.find(<id>)
Flipper.enable(:agent_framework, restaurant)
Flipper.enable(:agent_menu_import, restaurant)
```

---

## How to Use It

### Step 1 — Upload a PDF menu as usual

Go to the restaurant's **OCR Import** section and upload a PDF menu (or the import will be created as part of your normal import flow). Once the import record is created, the agent is triggered automatically — no additional action is needed.

### Step 2 — Wait for the agent to process

The agent runs as a background job (Sidekiq queue: `agent_high`). For a typical 50-item menu, expect 2–5 minutes for the full pipeline to complete. You'll receive an email notification when the draft is ready for review.

### Step 3 — Review in the AI Workbench

Navigate to:
```
/restaurants/<id>/agent_workbench
```

Find the **menu_import** workflow run. Click on it and then click **"Review & Publish"** to open the diff review screen.

### Step 4 — Approve or reject items

The review screen shows:

- **Summary bar**: total sections, total items, auto-approved count, items needing review.
- **Pending Approvals**: any item with allergen claims or low confidence appears here. You must resolve all of these before publishing.
  - Click **"Approve Item"** to accept the proposed item.
  - Click **"Reject Item"** (with optional reason) to exclude it from the import.
- **Proposed Menu Items**: a full list of all items with their confidence scores, proposed tags, and allergen badges.

### Step 5 — Publish

Once all pending approvals are resolved, the **"Publish to Live Menu"** button becomes active. Click it to promote all approved items to live `Menuitem` records via the existing `ImportToMenu` service.

---

## Confidence Scoring

| Score | Meaning |
|-------|---------|
| 0.8–1.0 | Auto-approved (if no allergens) |
| Below 0.8 | Requires manual approval |
| N/A (nil) | Requires manual approval |

**Allergen rule (non-negotiable):** Any item with an allergen claim ALWAYS requires manager sign-off, regardless of confidence score.

---

## Proposed Tags

The agent assigns tags from this list: `vegan`, `gluten-free`, `spicy`, `premium`, `kids`, `high-margin`, `dairy-free`, `nut-free`. These are stored as `proposed_tags` on the `OcrMenuItem` record and can be used for filtering and future AI enrichment.

---

## What the Agent Never Does

- **Never writes directly to live `Menuitem` records.** All output goes through `AgentArtifact` → manager approval → `ImportToMenu` service.
- **Never auto-applies allergen data** without explicit manager sign-off.
- **Never re-runs a step** that has already completed (the pipeline is resumable: if the Sidekiq worker is killed mid-run, it resumes from the last completed step).

---

## Viewing the Full Audit Trail

Every step, LLM call, tool invocation, and approval decision is recorded in the AI Workbench run detail page (`/restaurants/<id>/agent_workbench/<run_id>`). The full audit trail is available indefinitely.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No workflow run created after upload | `agent_framework` or `agent_menu_import` flag not enabled for this restaurant | Enable both flags (see Prerequisites) |
| Run stuck in `pending` | `agent_high` Sidekiq queue not processing | Check Sidekiq worker for the `agent_high` queue |
| Run `failed` with OpenAI error | API key missing or quota exceeded | Check `OPENAI_API_KEY` env var; check OpenAI billing |
| "No import found for this workflow run" on publish | Import was not linked to the run (unusual) | Check `ocr_menu_imports.agent_workflow_run_id` for the import |
| "All pending approvals must be resolved" | Pending `AgentApproval` records remain | Approve or reject all flagged items in the review screen |

---

## Developer Notes

- **Flipper flags**: `agent_framework` (master), `agent_menu_import` (per-restaurant)
- **Domain event**: `menu.import.requested` (emitted by `OcrMenuImport` `after_create`)
- **Workflow service**: `app/services/agents/workflows/menu_import_workflow.rb`
- **Job**: `app/jobs/agents/menu_import_workflow_job.rb` (queue: `agent_high`)
- **Publisher**: `app/services/agents/menu_import_publisher.rb`
- **New tool**: `Agents::Tools::FetchMenuSource`
- **DB columns added**: `ocr_menu_imports.{agent_workflow_run_id, confidence_score, agent_status}`, `ocr_menu_items.{confidence_score, agent_approval_status, proposed_tags}`

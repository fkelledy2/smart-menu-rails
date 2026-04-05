---
name: Reputation & Feedback Agent v1
description: Reputation & Feedback Agent v1 (#23): GuestRating model, 4-step workflow, DetectAbandonedPaymentsJob, rating widget, workbench UI (April 2026)
type: project
---

Reputation & Feedback Agent v1 (#23) shipped 2026-04-05.

**Why:** Protects revenue by surfacing negative signals (low ratings, complaints, abandoned payments) to managers within 5 minutes — with AI-drafted recovery messages requiring explicit approval before any customer communication.

**Architecture:**
- `GuestRating` model — stores 1–5 star ratings; emits `rating.low` AgentDomainEvent when stars <= 2
- `GuestRatingsController` — unauthenticated POST endpoint; uses `CsrfSafeGuestActions`; route: `guest_rating_restaurant_ordr_path(restaurant, ordr)` (member of ordrs)
- `Agents::Workflows::ReputationFeedbackWorkflow` — 4-step pipeline (read_context, classify_and_reason, write_recovery_draft, notify_manager)
- `Agents::ReputationFeedbackWorkflowJob` — queue: `agent_high`
- `Agents::DetectAbandonedPaymentsJob` — queue: `agent_default`, cron every 10 min; detects billrequested/active orders older than 30 min; idempotent via JSONB `payload @> ?` query with GIN index
- Tools: `ReadOrderContext`, `DraftRecoveryMessage`, `DraftReviewResponse`
- `AgentReputationMailer` — severity-prefixed subject, [Action Required]/[Review Soon]/[FYI]
- `AgentRecoveryMailer` — delivers manager-approved customer recovery messages only
- Migration `20260405200001` — creates `guest_ratings` table with check constraint `stars BETWEEN 1 AND 5`

**Flipper flags:** `agent_framework` + `agent_reputation_feedback` (both must be enabled per restaurant)

**Key gotchas:**
- Route uses `params[:id]` for ordr (not `params[:ordr_id]`) because it's a `member do` route inside `resources :ordrs`
- `guest_rating_form` partial guards with `GuestRating.exists?(ordr_id: order.id, source: 'in_app')` to prevent duplicate widget render
- All `AgentApproval` records created by this agent have `risk_level: 'high'` — never auto-approved
- Payment abandoned detection uses `paymentstatus: 0` (default integer) as "unpaid" signal
- Systemic issue detection queries JSONB: `content->>'root_cause' = ?` — this is a text cast, works correctly with PostgreSQL
- LLM classification uses fallback_classification (severity: medium) if OpenAI fails
- Domain event JSONB idempotency check uses GIN index: `payload @> ?` with `{ ordr_id: ... }.to_json`

**Controller additions to AgentWorkbenchController:**
- `GET reputation` — dashboard with 4-week stats
- `GET :id/reputation_review` — triage card for a single run
- `POST :id/send_recovery_message` — sends approved message via AgentRecoveryMailer

**Accepted scope limitations (v1):**
- No external review ingestion (Google/TripAdvisor) — in-app signals only
- Recovery message requires manual email entry by manager
- Discount codes are advisory only
- Review posting is copy-paste only

**How to apply:** When building agents that need post-dining feedback signals, use the `rating.low` / `complaint.submitted` / `review.received` event types. The GuestRating model is the canonical source for in-app ratings.

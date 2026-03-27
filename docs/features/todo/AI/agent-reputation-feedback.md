# Reputation & Feedback Agent

## Status
- Priority Rank: #22 (Phase 2 agent — requires in-app rating/feedback system to be active; meaningful only after restaurants have been live long enough to receive reviews)
- Category: Post-Launch — agent tier, Phase 2
- Effort: M
- Dependencies: Agent Framework (#16), in-app rating at checkout (confirm existing), `Ordr` / `Ordritem` models (existing), email mailers (existing), OpenAI API

## Problem Statement
Negative guest experiences compound quickly if left unaddressed: a 2-star rating with no response, a complaint ignored for 48 hours, or an abandoned payment tab that a manager never noticed. Restaurant owners currently receive these signals through disparate channels — a Google Review notification, an in-app rating at checkout, a support message — with no structured triage or response workflow. By the time a manager notices and drafts a response, the reputational window has closed. The Reputation & Feedback Agent monitors post-dining signals in real time, classifies their severity, drafts targeted recovery responses, and surfaces them to the manager with all the context needed to act — within minutes, not days. Critically, this agent never sends any communication autonomously. Every outbound message requires explicit manager sign-off.

## Success Criteria
- Low ratings (1–2 stars) generate a manager notification with a drafted recovery response within 5 minutes of the signal being received.
- Manager response rate to low-rating alerts exceeds 50% within 3 months of launch (indicates the agent is saving time, not just adding noise).
- Public review response drafts are reviewed and sent within 24 hours of the review being received (track response time as a key metric).
- No outbound customer communication is ever sent without explicit manager approval — this is non-negotiable.
- Abandoned payment flags result in staff follow-up action on at least 40% of flagged cases within 1 hour.

## User Stories
- As a restaurant manager, I want to be alerted immediately when a customer leaves a low rating, with a suggested response, so I can address it before the customer leaves the area.
- As a restaurant owner, I want AI-drafted responses to Google/TripAdvisor reviews ready for my approval, so I can respond quickly without spending 20 minutes writing each one.
- As a restaurant manager, I want abandoned payment tabs flagged with the customer's order context so my staff can follow up promptly.
- As a restaurant owner, I want to see an aggregate view of complaints, ratings, and my response rate so I can track how my reputation management is improving.
- As a customer (implicit), I want to feel heard when I leave negative feedback — knowing the restaurant responds quickly and personally.

## Functional Requirements

1. The agent responds to four trigger domain events: `review.received`, `rating.low` (1–2 stars at checkout), `complaint.submitted`, `payment.abandoned`.
2. `Agents::Dispatcher` maps all four events to `Agents::ReputationFeedbackWorkflowJob` on the `agent_high` queue (these are time-sensitive signals).
3. The workflow pipeline:
   - **Step 1: read_context** — read the full order context for the affected session: `Ordr`, all `Ordritem` records, table number, server, timing, rating value, and the review/complaint text. For `review.received`, also read the review source (in-app / Google / TripAdvisor) and the full review text.
   - **Step 2: classify_and_reason** — OpenAI Responses API call. Input: signal type, order context, rating/review text. Output: severity classification (low / medium / high), likely root cause (wait_time / wrong_item / quality / price / service / other), draft recovery message (personalised to the order context), and — for `review.received` — a draft public response.
   - **Step 3: write_recovery_draft** — `Agents::ArtifactWriter` writes an `AgentArtifact` with type `reputation_recovery` containing: severity, root cause, draft customer message, draft review response (if applicable), suggested action (discount_offer / comp / direct_message / no_action). Creates `AgentApproval` records for all actions requiring manager sign-off.
   - **Step 4: notify_manager** — `Agents::ApprovalRouter` pushes a notification to the manager's back office and sends an email alert with the severity, a one-sentence summary, and a direct link to the approval screen. High-severity signals also trigger an in-app notification via `UserChannel`.
4. **Manager approval screen** (`/restaurants/:id/agent_workbench/reputation`): each item shows — signal type (rating/review/complaint/abandoned), order context summary, AI severity classification, AI root cause analysis, draft response text (editable), and action buttons: "Send Message" / "Post Response" / "Offer Discount" / "Flag for Ops Review" / "Dismiss".
5. Sending a recovery message goes through the existing `ApplicationMailer` infrastructure — the agent does not add a new email provider. The manager edits the draft and clicks "Send" — this triggers a standard mailer delivery, not an autonomous agent action.
6. For `payment.abandoned`: the agent flags the order in the manager's notification feed with: order details, items ordered, total unpaid, time elapsed. No automated communication to the customer — staff follow-up is manual.
7. For `review.received`: the draft review response is stored as an `AgentArtifact`. The manager edits and approves it. Posting the response to Google/TripAdvisor is out of scope for v1 — the manager copies and pastes. A "Copy response" button is provided.
8. Aggregate reputation dashboard widget in the back office: complaint rate by week, average rating, response rate, average time to respond. Feeds from `AgentWorkflowRun` and `AgentApproval` records.
9. Systemic issue detection: if 3 or more signals with the same `root_cause` are classified within 7 days, the agent creates an additional notification flagging a potential systemic issue (e.g. "3 complaints about wait time this week — possible kitchen throughput issue"). This is advisory only.

## Non-Functional Requirements
- `rating.low` and `complaint.submitted` signals must result in a manager notification within 5 minutes.
- `review.received` signals (less time-critical) can be processed within 15 minutes.
- `payment.abandoned` detection requires a scheduled check: `DetectAbandonedPaymentsJob` runs every 10 minutes and emits `payment.abandoned` events for orders with `payment_status: pending` and last activity > configurable threshold (default: 30 minutes).
- All outbound communication requires manager approval — there is no `auto_approve` policy for any customer-facing action in this agent.
- Draft responses must not hallucinate menu items, prices, or order details — the LLM receives the full structured order context and must be instructed to reference only what is in that context.
- GDPR: customer personal data (name, email, order history) accessed by this agent is for back-office manager review only. Drafts are never stored with raw PII beyond what is already stored in `Ordr` / `Ordrparticipant`.
- Flipper flag `agent_reputation_feedback` must be enabled per restaurant.

## Technical Notes

### New Services
- `agents/workflows/reputation_feedback_workflow.rb`

### New Jobs
- `agents/reputation_feedback_workflow_job.rb` — `agent_high` queue
- `agents/detect_abandoned_payments_job.rb` — Sidekiq cron every 10 minutes; queries `Ordr` for pending-payment records older than threshold; emits `payment.abandoned` domain events; idempotent (skip if event already emitted for this order in the past hour)

### New Tool
- `tools/read_order_context.rb` — reads a full `Ordr` record with all associated `Ordritem`, `Ordrparticipant`, `OrdrAction` records, plus table and server context. Returns structured hash. Add to `Agents::Toolbox`.
- `tools/draft_recovery_message.rb` — OpenAI call to generate personalised customer recovery message. Input: order context, root cause, signal type. Output: email subject + body string.
- `tools/draft_review_response.rb` — OpenAI call to generate a professional public review response. Input: review text, star rating, restaurant context. Output: response string.

### Existing Mailer Integration
- The "Send Message" action in the approval screen calls an existing mailer (or creates `AgentRecoveryMailer`) with the manager-approved message text. No new email provider needed.
- `AgentRecoveryMailer` uses the branded layout (Feature #2 dependency).

### In-App Rating System
- Confirm that in-app star rating at checkout emits (or can be extended to emit) a `rating.low` domain event when the rating is 1 or 2 stars. If the rating model does not yet exist as a domain event source, add the event emission to the rating submission controller action.

### `DetectAbandonedPaymentsJob` Idempotency
- Before emitting a `payment.abandoned` event, check `AgentDomainEvent` table for an existing unprocessed event for the same `ordr_id` with type `payment.abandoned`. If one exists and is < 1 hour old, skip.
- Add `ordr_id` index to `AgentDomainEvent` for efficient lookups.

### Flipper Flags
- `agent_framework` (required)
- `agent_reputation_feedback`

## Acceptance Criteria
1. A 1-star rating submitted at checkout creates a `rating.low` domain event and enqueues `Agents::ReputationFeedbackWorkflowJob` within 30 seconds.
2. The workflow completes in under 5 minutes and creates an `AgentArtifact` with type `reputation_recovery` containing: severity, root cause, draft customer message.
3. The manager receives a back-office notification and email with a link to the approval screen.
4. The draft customer message references the customer's actual order items, not hallucinated content — verified by checking the draft against the test order's `Ordritem` records.
5. Clicking "Send Message" on the approval screen (after editing) triggers the mailer. No message is sent if the manager has not visited the approval screen and taken action.
6. A `payment.abandoned` event is emitted by `DetectAbandonedPaymentsJob` for an `Ordr` with `payment_status: pending` and last activity 35 minutes ago. It is not emitted again within the next 60 minutes for the same order (idempotency).
7. Three `rating.low` signals with `root_cause: wait_time` within 7 days trigger a "potential systemic issue" advisory notification in the manager's back office.
8. A `review.received` event produces an `AgentArtifact` with a draft public review response. The manager's approval screen includes a "Copy response" button and an inline editor. No automated posting to any review platform occurs.
9. All `AgentApproval` records for reputation recovery actions have `risk_level: high` and the `auto_approve` policy is never applied to any outbound customer communication action.
10. With `agent_reputation_feedback` flag disabled, low-rating events are stored as `AgentDomainEvent` records but no workflow job is enqueued.

## Out of Scope
- Automated posting of responses to Google/TripAdvisor/Yelp (API integration with review platforms — post-launch).
- Automated issuance of discount codes or refunds without manager approval — never in scope.
- Sentiment analysis of menu item descriptions.
- Real-time chat or two-way messaging with customers.
- Review monitoring for platforms not integrated with the platform's review ingestion pipeline (Google/TripAdvisor ingestion requires a separate integration spec — assumed as future work).

## Open Questions
1. Does the platform currently have a mechanism for receiving Google/TripAdvisor reviews? If not, `review.received` events can only be triggered by in-app feedback at checkout in v1. The spec should be scoped to in-app signals first, with external review ingestion as a v2 extension. Needs product confirmation.
2. What field on `Ordr` tracks payment status? Confirm the correct field/enum value for "pending payment" to drive `DetectAbandonedPaymentsJob`.
3. Should the "offer discount" action generate a discount code via the existing discount/promo system? If no discount code system exists, this action is advisory text only in v1.
4. Is there a per-customer identity model that links a dining session to a returnable customer? If not, "recovery message" can only be delivered by email captured at checkout — confirm whether email capture at checkout is implemented.

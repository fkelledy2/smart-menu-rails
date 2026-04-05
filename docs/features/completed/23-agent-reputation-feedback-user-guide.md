# Reputation & Feedback Agent — User Guide

**Feature #23 | Shipped: 2026-04-05**

---

## What This Feature Does

The Reputation & Feedback Agent monitors post-dining signals in near real-time, classifies their severity, drafts targeted recovery responses, and surfaces them to the restaurant manager for action — typically within 5 minutes of the signal being received.

**Critical rule:** The agent never sends any communication to customers autonomously. Every outbound message requires explicit manager sign-off.

---

## Signals the Agent Responds To

| Signal | Trigger |
|--------|---------|
| Low rating (`rating.low`) | Guest submits 1 or 2 stars at checkout via the smartmenu |
| Complaint (`complaint.submitted`) | Published by other systems or future integrations |
| Review received (`review.received`) | In-app review or future external platform ingestion |
| Abandoned payment (`payment.abandoned`) | Order stuck in `billrequested` or active state for > 30 min with no payment |

---

## For Restaurant Managers / Owners

### Enabling the Agent

Ask your mellow.menu administrator to enable these two feature flags for your restaurant:

- `agent_framework` — base requirement for all agents
- `agent_reputation_feedback` — enables this specific agent

### Accessing the Dashboard

Navigate to: **Back Office → AI Workbench → Reputation & Feedback**

URL pattern: `/restaurants/:id/agent_workbench/reputation`

The dashboard shows:
- Total signals in the past 4 weeks
- High-severity count
- Signals awaiting your action
- Your response rate (target: > 50%)

### Handling a Low Rating

1. You receive an email alert with a severity badge and a one-sentence summary.
2. Click the **Review in Back Office** link in the email.
3. On the triage screen you will see:
   - The signal type and star rating
   - The AI-classified severity and root cause
   - The order context (table, items ordered, total)
   - A draft recovery message (editable)
4. **To send a recovery message:**
   - Enter the customer's email address
   - Edit the draft message as needed (the draft is grounded to actual order items — do not invent details)
   - Click **Send Message** — this sends the email and records your approval
5. To dismiss without action: click **Dismiss**.

### Handling an Abandoned Payment

Abandoned payments are flagged for **manual staff follow-up only** — no automated message is sent. The triage screen shows the order details (table, items, total unpaid). Ask staff to investigate directly.

### Handling an In-App Review

If a `review.received` event is processed, the triage screen provides:
- A draft public review response (AI-generated, editable)
- A **Copy response** button

Copy the response, then post it manually on the review platform (Google, TripAdvisor, etc.). Automated posting to external platforms is not available in v1.

### Systemic Issue Alerts

If 3 or more signals share the same root cause (e.g. wait time, wrong item) within 7 days, the agent creates a **Pattern Alert** notification in your back office and includes a note in the email. This is advisory only — it flags a potential systemic problem (e.g. kitchen throughput) for you to investigate.

---

## For Restaurant Staff (at checkout)

Guests will see a **star rating widget** in the cart bottom sheet after their order is paid or closed. The widget:
- Shows 5 stars
- Reveals a comment box when a star is tapped
- Submits via a single tap on "Submit"
- Shows a thank-you message on success

Ratings of 1 or 2 stars automatically trigger the Reputation & Feedback Agent within 30 seconds.

---

## Technical Reference

### Flipper Flags

| Flag | Purpose |
|------|---------|
| `agent_framework` | Must be enabled for any agent to run |
| `agent_reputation_feedback` | Enables the Reputation & Feedback Agent specifically |

If `agent_reputation_feedback` is disabled, low-rating events are still stored as `AgentDomainEvent` records but no workflow job is enqueued.

### Cron Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `Agents::DetectAbandonedPaymentsJob` | Every 10 minutes | Queries for stale orders and emits `payment.abandoned` events |

### Key Models

| Model | Purpose |
|-------|---------|
| `GuestRating` | Stores guest star ratings (1–5) with ordr reference |
| `AgentDomainEvent` | Durable event log that the Dispatcher polls |
| `AgentWorkflowRun` | Tracks each workflow execution lifecycle |
| `AgentArtifact` (type: `reputation_recovery`) | Stores severity, root cause, and draft messages |
| `AgentApproval` (action: `send_recovery_message`) | Manager approval gate — always `risk_level: high` |

### Routes Added

```
POST   /restaurants/:restaurant_id/ordrs/:id/guest_rating         guest_ratings#create
GET    /restaurants/:restaurant_id/agent_workbench/reputation      agent_workbench#reputation
GET    /restaurants/:restaurant_id/agent_workbench/:id/reputation_review   agent_workbench#reputation_review
POST   /restaurants/:restaurant_id/agent_workbench/:id/send_recovery_message  agent_workbench#send_recovery_message
```

### Event Flow

```
Guest submits 1-star rating
  → GuestRating.create!
    → emit_low_rating_event (after_create_commit)
      → AgentDomainEvent.publish!(event_type: 'rating.low')
        → Agents::PollDomainEventsJob (every 1 min) picks it up
          → Agents::Dispatcher.call(event)
            → checks agent_reputation_feedback Flipper flag
              → Agents::ReputationFeedbackWorkflowJob.perform_later
                → ReputationFeedbackWorkflow.call
                  Step 1: read_context
                  Step 2: classify_and_reason (LLM)
                  Step 3: write_recovery_draft → AgentArtifact + AgentApproval
                  Step 4: notify_manager → email + UserChannel push
```

---

## Known Limitations (v1)

- **No external review ingestion:** `review.received` events can only be triggered programmatically or by in-app feedback; there is no direct Google/TripAdvisor/Yelp API integration yet.
- **Recovery messages require customer email:** The send form requires the manager to enter the customer's email address manually. There is no automatic email capture at checkout yet.
- **Discount codes are advisory only:** The "discount_offer" suggested action does not generate a promo code automatically. It is an advisory label only.
- **Review posting is copy-paste only:** The public review response must be copied and pasted to the review platform manually.

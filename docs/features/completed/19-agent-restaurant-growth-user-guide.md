# Restaurant Growth Agent — User Guide

**Feature ID**: #19  
**Status**: Completed 2026-04-01  
**Flipper flags**: `agent_framework` (master), `agent_growth_digest` (per-restaurant)

---

## What Is It?

The Restaurant Growth Agent automatically analyses your restaurant's last 7 days of performance data and delivers a concise, actionable weekly digest every Monday morning. It identifies your best and worst-performing items, suggests specific actions (remove, reprice, refresh the image), and writes ready-to-use social media and email marketing copy — all without you having to open a single dashboard.

The agent never changes anything automatically. Every recommendation is advisory only.

---

## Enabling the Feature

1. Go to the **Flipper** admin UI (`/flipper`) as a super-admin.
2. Enable `agent_framework` for the restaurant (or globally, if it is not already on).
3. Enable `agent_growth_digest` for the restaurant.

Once both flags are on, the restaurant will receive its first digest the following Monday (or you can trigger one immediately — see below).

---

## The Weekly Digest

Every Monday at 06:00 UTC, the platform checks which restaurants:
- Have `agent_framework` and `agent_growth_digest` enabled
- Have at least **5 orders in the past 7 days**

Eligible restaurants receive a digest email sent to all users with the `manager` or `admin` (owner) role.

### What the digest contains

| Section | Description |
|---------|-------------|
| Summary | One paragraph written by the AI summarising the week |
| Weekend Recommendation | A specific, actionable tip for the upcoming weekend service |
| Top Performers | Up to 5 items with the highest order volume this week |
| Actions to Consider | Up to 8 underperformers, repricing candidates, and friction items — each with a suggested action |
| Marketing Copy | Ready-to-use Instagram caption and email/newsletter copy for your best-margin or best-selling item |

### Performance buckets

Every menu item is tagged with one or more of these buckets before the AI analysis:

| Bucket | Meaning |
|--------|---------|
| `top_mover` | Ordered significantly more than the median item this week |
| `slow_mover` | Ordered below half the median, or zero orders |
| `high_margin` | Profit margin >= 60% |
| `low_margin` | Profit margin < 30% (and costs entered) |
| `low_friction` | High order share — customers who browse it tend to order it |
| `high_friction` | Visible on the menu but rarely ordered |

---

## Back-Office Digest View

Navigate to **AI Workbench > Growth Digest** from any restaurant back-office:

```
/restaurants/:id/agent_workbench/digests
```

This page shows the last 8 weeks of digest history. The most recent digest is highlighted at the top.

### Insight cards

Each insight card shows:
- Item name and performance label
- The AI's reasoning
- Suggested action badge (Reprice, Review, Reimage, etc.)

### Marketing copy

Each digest card includes a copy-to-clipboard button for both the Instagram caption and the email body. Click **Copy** and paste directly into your social media scheduler or newsletter tool. A "Share to Instagram" direct integration is marked "coming soon" in v1.

---

## Generating a Digest On Demand

If you want a fresh digest right now (not waiting until Monday):

1. Go to `/restaurants/:id/agent_workbench/digests`
2. Click **Generate Now**
3. The digest will appear within 10 minutes (faster if the Sidekiq queue is clear)

Only one digest can be in progress at a time. If a digest is already being generated, the button is disabled and a notice is shown.

---

## Minimum Data Requirement

A restaurant needs at least **5 orders in the past 7 days** to receive a meaningful digest. Restaurants below this threshold are skipped by the weekly scheduler. You can still trigger an on-demand digest for restaurants below the threshold — the agent will work with whatever data exists but the insights will be less specific.

---

## Fallback Behaviour

If the OpenAI API is unavailable:
- The job retries 3 times with exponential backoff.
- If all retries fail, the digest falls back to a **raw data summary only** (top movers / slow movers listed without AI narrative or marketing copy).
- The manager still receives the fallback digest — no unhandled error reaches the UI.

---

## Technical Reference

| Component | Path |
|-----------|------|
| Workflow | `app/services/agents/workflows/manager_digest_workflow.rb` |
| Workflow job | `app/jobs/agents/manager_digest_workflow_job.rb` |
| Weekly trigger job | `app/jobs/agents/emit_manager_digest_events_job.rb` |
| Mailer | `app/mailers/agent_digest_mailer.rb` |
| Mailer views | `app/views/agent_digest_mailer/` |
| Controller (digest actions) | `app/controllers/restaurants/agent_workbench_controller.rb` |
| Back-office view | `app/views/restaurants/agent_workbench/digests.html.erb` |
| New tool | `app/services/agents/tools/draft_marketing_copy.rb` |
| Stimulus clipboard controller | `app/javascript/controllers/clipboard_controller.js` |

### Heroku Scheduler

To activate the weekly schedule, add the following job to **Heroku Scheduler**:

```
bundle exec rails runner "Agents::EmitManagerDigestEventsJob.perform_now"
Schedule: Weekly — Monday at 06:00 UTC
```

---

## Digest Retention

The digest history view returns the last **8 weeks** of growth digest artifacts. Older artifacts remain in the database but are not shown in the UI. No automatic deletion occurs in v1.

---

## Known Limitations (v1)

- Marketing copy "Share to Instagram" button is a stub — direct posting is not implemented.
- Digest frequency is fixed at weekly. Per-restaurant configurable cadence is v2.
- Cross-restaurant benchmarking ("your margins vs. similar restaurants") is out of scope for v1.
- The browse-to-order conversion rate used in friction detection is approximated from order share rather than raw browse events.

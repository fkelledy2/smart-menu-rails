# Global Payments

PSP-agnostic payments architecture for Smartmenu (Rails 7) with Stripe as Provider #1.

## Current status
- Phase 1 (PSP-agnostic core): implemented.
- Phase 2 (Stripe Connect onboarding): implemented.
- Phase 3 (MoR selection + routing): implemented (guarded behind Stripe Connect enabled).

## Goals
- Support **dual Merchant-of-Record (MoR)** per restaurant (Restaurant MoR vs Smartmenu MoR).
- Run globally wherever the selected PSP supports it (starting with Stripe).
- Avoid provider lock-in via a **provider adapter** boundary.
- Keep Smartmenu as the source of truth for orders; keep payment state synchronized via webhooks.

## Non-goals (v1)
- Implement Provider #2.
- Full accounting / revenue recognition.
- Fraud ML (use PSP tooling initially).

## Confirmed stack
Rails 7, Postgres, Redis, Turbo/Hotwire, Sidekiq, Heroku.

## Key entry points
- Outbound payment creation: `app/controllers/payments/payment_attempts_controller.rb`, `app/services/payments/orchestrator.rb`, `app/services/payments/providers/stripe_adapter.rb`.
- Inbound webhooks: `app/controllers/payments/webhooks_controller.rb`, `app/jobs/payments/webhook_ingest_job.rb`, `app/services/payments/webhooks/stripe_ingestor.rb`.
- Stripe Connect onboarding: `app/controllers/payments/stripe_connect_controller.rb`, `app/services/payments/providers/stripe_connect.rb`.
- MoR selection: `app/controllers/payments/payment_profiles_controller.rb`, `app/views/restaurants/sections/_settings_2025.html.erb`.

## Files
- `01-overview.md`
- `10-architecture.md`
- `20-data-model.md`
- `30-flows.md`
- `40-provider-contract.md`
- `50-stripe-mapping.md`
- `60-open-questions.md`
- `70-rollout-plan.md`

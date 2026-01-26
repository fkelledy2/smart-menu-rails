# Global Payments

PSP-agnostic payments architecture for Smartmenu (Rails 7) with Stripe as Provider #1.

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

## Files
- `01-overview.md`
- `10-architecture.md`
- `20-data-model.md`
- `30-flows.md`
- `40-provider-contract.md`
- `50-stripe-mapping.md`
- `60-open-questions.md`
- `70-rollout-plan.md`

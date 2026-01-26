# 70 — Rollout Plan

## Phase 0 (now)
- Document architecture.
- Add PSP-agnostic tables (migrations) behind feature flags.
- Implement adapter interface + StripeAdapter wrapper around existing Stripe code.

## Phase 1 (Stripe-only, PSP-agnostic core)
- Create payment attempts via orchestrator.
- Webhook ingest -> normalized events -> ledger -> order projection.
- Store raw webhook payloads in DB.
- Snapshot `payment_profiles.merchant_model` onto `payment_attempts`.
- Refunds: admin-only, full refunds only.
- Tips excluded from payment amount.
- Restaurant configuration via `payment_profiles` (default Stripe).

## Phase 2 (Connect onboarding)
- Add `provider_accounts` for Stripe Connect.
- Admin onboarding flows (AccountLink generation) and state tracking.

## Phase 3 (dual MoR)
- Enable restaurant-level MoR selection.
- Implement routing patterns per MoR.

## Phase 4 (Provider #2)
- Implement second adapter and capability routing.

## Release management
- Feature flags per restaurant.
- Backfill existing Stripe v1 payments into the new ledger only if needed.

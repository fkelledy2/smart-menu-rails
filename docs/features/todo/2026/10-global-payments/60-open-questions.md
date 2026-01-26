# 60 — Open Questions / Decisions

## Phase 1 decisions (locked)
- MoR is configured per restaurant via `payment_profiles.merchant_model` and snapshotted onto `payment_attempts.merchant_model`.
- Refunds are admin-only and full refunds only.
- Tips are not part of the payment amount.
- Raw webhook payload storage strategy is DB.

## Product / policy
- For each restaurant, do we allow switching MoR after onboarding? If yes, what guardrails?

## Compliance
- When Smartmenu is MoR, do we integrate Stripe Tax (or equivalent) immediately?
- What is the initial tax calculation strategy?

## Money movement
- If Smartmenu is MoR:
  - do we start with destination charges only, then add separate charges/transfers?
  - how do we handle corridor constraints?
- Settlement timing policy: immediate vs delayed vs batched.

## Provider strategy
- What is Provider #2 target and why? (Adyen vs Checkout.com vs others)
- Minimum common denominator payment methods we commit to across providers.

## Data / reconciliation
- Reconciliation cadence and alerting thresholds.

# 01 — Overview

## Context
This project extends the existing **Payments Moments (Stripe-led) (v1)** work in Smartmenu.

The current v1 implementation supports customer payments via Stripe Checkout and webhook-driven order state transitions.

## Goal
Build a **PSP-agnostic** payments platform ("Global Payments") so Stripe is Provider #1, not the architecture.

## Key outcomes
- **Per-restaurant** choice of Merchant-of-Record (MoR)
  - Restaurant MoR
  - Smartmenu MoR
- Provider-agnostic payment attempts + ledger.
- Provider-specific logic isolated behind:
  - adapters (outbound API calls)
  - webhook gateways (inbound event verification + normalization)

## Guiding principles
- **Order truth lives in Smartmenu** (orders, items, bill request, totals).
- **Money truth comes from PSP webhooks** (idempotent, append-only ledger).
- **No provider fields in core domain tables** (no `stripe_*` columns in new Global Payments tables).
- **Configuration as data**: per-restaurant payment profile + capability matrix.

## Phase 1 decisions
- MoR is configured per restaurant via `payment_profiles.merchant_model` and snapshotted onto `payment_attempts.merchant_model`.
- Refunds are admin-only and full refunds only.
- Tips are not part of the payment amount.
- Raw webhook payload storage strategy is DB.

## Stack constraints
- Rails 7 + Postgres + Redis + Sidekiq + Hotwire + Heroku.
- Mobile-first web only.

## Definitions
- **PSP**: Payment service provider (Stripe, Adyen, Checkout.com, etc.).
- **MoR**: Merchant of record (legal seller; affects tax/refunds/disputes).
- **Funds flow / charge pattern**:
  - `direct` (charge on restaurant account)
  - `destination` (platform charges, funds routed to restaurant)
  - `separate` (platform charges, then separate transfer/settlement)

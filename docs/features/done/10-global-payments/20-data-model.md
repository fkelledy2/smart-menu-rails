# 20 — Data Model (PSP-agnostic)

## Why new tables
To avoid PSP lock-in, new Global Payments tables must not contain provider-specific columns (no `stripe_*`).

## Proposed tables

### `payment_profiles`
One per restaurant (v1) defining policy.

Fields (suggested):
- `restaurant_id` (FK, unique)
- `merchant_model` enum: `restaurant_mor` | `smartmenu_mor`
- `primary_provider` enum: `stripe` (v1)
- `fallback_providers` jsonb (future)
- `default_country` (string)
- `default_currency` (string)
- `fee_model` jsonb (platform pricing rules)

### `provider_accounts`
Represents the restaurant’s identity/account within a provider.

Fields:
- `restaurant_id` (FK)
- `provider` enum: `stripe` | ...
- `provider_account_id` (string)
- `account_type` (string)
- `country`, `currency`
- `status` enum: `created` | `onboarding` | `enabled` | `restricted` | `disabled`
- `capabilities` jsonb
- `payouts_enabled` boolean

### `payment_attempts`
Provider-neutral record of an attempt to pay an order.

Fields:
- `ordr_id` (FK)
- `restaurant_id` (FK)
- `provider` enum
- `provider_payment_id` (string)
- `amount_cents` (integer)
- `currency` (string)
- `status` enum (provider-neutral):
  - `requires_action` | `processing` | `succeeded` | `failed` | `canceled`
- `charge_pattern` enum: `direct` | `destination` | `separate`
- `merchant_model` enum (snapshot from `payment_profiles.merchant_model`)
- `platform_fee_cents` (integer, nullable)
- `provider_fee_cents` (integer, nullable)

### `ledger_events`
Immutable append-only normalized events.

Fields:
- `entity_type` enum: `payment_attempt` | `refund` | `transfer` | `dispute` | `payout`
- `entity_id`
- `event_type` enum (normalized): `created` | `authorized` | `captured` | `succeeded` | `failed` | `refunded` | `dispute_opened` | ...
- `amount_cents`, `currency`
- `provider` enum
- `provider_event_id` (string)
- `provider_event_type` (string)
- `raw_event_payload` (jsonb)
- `occurred_at` (datetime)

## Idempotency
- Unique constraint: `(provider, provider_event_id)` on `ledger_events`.
- Optional: `(provider, provider_payment_id)` on `payment_attempts` when known.

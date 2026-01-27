# 40 — Provider Contract (Adapters + Webhooks)

## Adapter boundary
The core system talks to an abstract provider interface.

## Ruby module shape (suggested)
- `Payments::Providers::BaseAdapter`
- `Payments::Providers::StripeAdapter`

## Required capabilities
### Outbound
- Create a payment (return next action).
- Create a refund (v1: admin-only, full refunds only).

### Inbound
- Verify webhook signature.
- Normalize a provider webhook event into internal events.

## Normalized event format
A normalized event is provider-neutral and is the only thing the rest of the system consumes.

Fields:
- `provider`
- `provider_event_id`
- `provider_event_type`
- `occurred_at`
- `entity_type` (payment_attempt/refund/transfer/...)
- `entity_lookup` (e.g. provider_payment_id)
- `event_type` (created/succeeded/failed/refunded/...)
- `amount_cents`, `currency`
- `metadata` (order_id, restaurant_id, split ids)

## Mapping rule
- Provider-specific objects/fields must be translated into normalized events.
- Core services operate only on normalized events.

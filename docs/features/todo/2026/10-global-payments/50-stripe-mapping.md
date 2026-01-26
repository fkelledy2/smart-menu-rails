# 50 — Stripe Mapping (Provider #1)

## What we already have
Existing v1 Stripe Checkout integration:
- Checkout Session creation with metadata + `client_reference_id`.
- Webhook handling in `Payments::WebhooksController` emitting `OrderEvent` and projecting.

## Stripe Connect (future within this project)
For restaurant payouts, Stripe Connect introduces **connected accounts**.

### Stripe objects
- Connected Account: `acct_...`
- Account onboarding link
- PaymentIntent / Checkout Session
- Optional Transfer (separate charges + transfers)

## Mapping to MoR
### Restaurant MoR
- Prefer **direct charges** (charge created on connected account).

### Smartmenu MoR
- Prefer destination/separate patterns depending on corridor.

## Stripe webhooks (subset)
- `checkout.session.completed`
- `payment_intent.succeeded`
- `charge.refunded`
- (later) `charge.dispute.*`
- (later) `transfer.*`
- (later) `account.updated`

## Key correlation fields
- `metadata.order_id`
- `metadata.restaurant_id`
- `client_reference_id` fallback

## Security
- Webhook signature verification required in production.
- Local dev uses Stripe CLI + forwarding.

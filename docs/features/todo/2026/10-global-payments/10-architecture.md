# 10 — Architecture

## Baseline (today)
- Customer pays via Stripe Checkout.
- Webhooks update orders by emitting `OrderEvent` and projecting via `OrderEventProjector`.

## Target architecture (PSP-agnostic)

### Layers
- **Controllers**: request/response (no money logic)
- **Orchestrator**: validates + selects provider + delegates
- **Router**: selects funds flow / charge pattern
- **Provider adapter**: outbound PSP API
- **Webhook gateway**: inbound PSP webhook verification + normalization
- **Ledger**: append-only normalized events + reconciliation

### Rails components
- `Payments::PaymentsController` (new)
  - `POST /payments/payment_attempts` (create attempt / start payment)
  - `POST /payments/refunds` (optional v1)
- `Payments::WebhooksController` (existing for Stripe v1)
  - becomes a thin gateway that calls the Stripe adapter/gateway and emits normalized events.

### Service objects
- `Payments::Orchestrator`
- `Payments::FundsFlowRouter`
- `Payments::Ledger`
- `Payments::Providers::BaseAdapter`
- `Payments::Providers::StripeAdapter` (Provider #1)

### Jobs (Sidekiq)
- `Payments::WebhookIngestJob`
  - verifies + normalizes + appends ledger + triggers projectors
- `Payments::ReconciliationJob`
  - compares PSP events/transactions vs internal ledger snapshots

## Data flow
1. Client requests payment for an order.
2. Orchestrator selects provider + pattern.
3. Adapter creates PSP payment object.
4. Client completes payment (redirect/SDK).
5. PSP sends webhook.
6. Webhook gateway verifies signature and normalizes into internal events.
7. Ledger appends events; projector updates order; UI updates via broadcast.

## Invariants
- Webhook processing is **idempotent**.
- Ledger is **append-only**.
- Order state changes only happen via internal domain events (e.g. `OrderEvent.emit!`).

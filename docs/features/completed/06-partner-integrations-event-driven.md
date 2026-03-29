# Partner Integrations (Event-Driven, Replaceable) (v1)

## Status
- Priority Rank: #11
- Category: Post-Launch
- Effort: M
- Dependencies: JWT Token Management (#8 — completed 2026-03-27), existing ActionCable event infrastructure, Payments::Webhooks (Stripe/Square ingestors)

## Problem Statement
mellow.menu produces rich real-time dining signals — order mutations, payment events, table occupancy — but has no formal mechanism for partners to consume them. This limits the platform's ecosystem value and prevents integration with workforce tools (scheduling, labour planning), CRM systems (guest analytics, retention), and messaging providers (receipts, nudges). An event-driven integration layer turns mellow.menu from an isolated product into a platform that partners can build on.

## Success Criteria
- A canonical partner event schema is defined and documented.
- Stripe `payment_intent.succeeded` webhooks are mapped to canonical order payment events and dispatched to registered adapter endpoints.
- A workforce signals export (order velocity, item prep times, table occupancy duration) is available as a read-only endpoint.
- A CRM signals export (in-meal behaviour, order pacing, time-to-pay) is available as a read-only endpoint.
- Each adapter has observable success/fail metrics and a dead-letter log.
- No partner UI is built inside mellow.menu for v1.

## User Stories
- As a workforce software partner, I want to consume mellow.menu order velocity and prep time data via a stable API so I can optimise staffing.
- As a CRM partner, I want to receive order pacing and time-to-pay signals so I can enrich guest profiles.
- As a mellow.menu admin, I want each integration to be independently replaceable without touching core order logic.
- As an engineer, I want dead-letter logging so failed integration dispatches are not silently dropped.

## Functional Requirements
1. Define a canonical partner event payload schema (JSON) that normalises mellow.menu domain events. Schema covers at minimum: order created, order status changed, order paid, table occupied, table freed.
2. Implement `PartnerIntegrationAdapter` interface: `call(event:)` method, replaceable per integration type.
3. Stripe webhook mapping: `payment_intent.succeeded` → canonical `order.payment.succeeded` event → dispatched to all registered adapters for the restaurant.
4. Workforce export endpoint: `GET /api/v1/restaurants/:id/partner/workforce` — returns order velocity (orders/minute over last N minutes), average item prep times (from order-to-ready timestamps), and table occupancy durations. JWT-protected with `workforce:read` scope.
5. CRM export endpoint: `GET /api/v1/restaurants/:id/partner/crm` — returns in-meal order pacing, time from first item added to bill requested, and table session duration. JWT-protected with `crm:read` scope.
6. Configuration per restaurant: `restaurant.enabled_integrations` (jsonb or join table) listing which adapter types are active.
7. Dead-letter logging: failed adapter dispatch writes a `partner_integration_error_log` record with: `restaurant_id`, `adapter_type`, `event_type`, `payload_json`, `error_message`, `created_at`.
8. Per-adapter metrics: success count, failure count, last dispatch time. Visible in admin area.

## Non-Functional Requirements
- Adapters are loosely coupled — adding or removing one must not require changes to core order processing.
- Adapter dispatch is asynchronous (Sidekiq job) — does not block the main request lifecycle.
- Canonical events are immutable once emitted — adapters cannot mutate the event payload.
- JWT authentication required for all partner API endpoints (see #8).
- Statement timeouts apply to all query-backed export endpoints.

## Technical Notes

### Services
- `app/services/partner_integrations/event_emitter.rb`: emits canonical events to all registered adapters for a restaurant.
- `app/services/partner_integrations/adapter.rb`: base adapter class with `call(event:)` interface.
- `app/services/partner_integrations/stripe_event_mapper.rb`: maps Stripe webhook payloads to canonical events.
- `app/services/partner_integrations/workforce_export_service.rb`: computes workforce signals for the export endpoint.
- `app/services/partner_integrations/crm_export_service.rb`: computes CRM signals for the export endpoint.

### Jobs
- `app/jobs/partner_integration_dispatch_job.rb`: Sidekiq job that calls the adapter `call` method. Retries with exponential backoff up to 3 times. On final failure, writes to dead-letter log.

### Models / Migrations
- `create_partner_integration_error_logs`: `restaurant_id`, `adapter_type`, `event_type`, `payload_json:jsonb`, `error_message:text`, `created_at`.

### Policies
- `app/policies/partner_integration_policy.rb`: restrict configuration changes to restaurant managers/owners.

### Webhook Integration
- Extend `Payments::Webhooks::StripeIngestor` to emit canonical events via `EventEmitter` after processing `payment_intent.succeeded`.

### Routes
```ruby
namespace :api do
  namespace :v1 do
    resources :restaurants do
      namespace :partner do
        get :workforce
        get :crm
      end
    end
  end
end
```

### Flipper
- `partner_integrations` — per-restaurant opt-in flag.

## Acceptance Criteria
1. When a Stripe `payment_intent.succeeded` webhook is processed, a canonical `order.payment.succeeded` event is emitted to all active adapters for the restaurant.
2. `GET /api/v1/restaurants/:id/partner/workforce` with a valid JWT (`workforce:read` scope) returns order velocity, prep times, and occupancy data.
3. `GET /api/v1/restaurants/:id/partner/crm` with a valid JWT (`crm:read` scope) returns order pacing and time-to-pay data.
4. A failed adapter dispatch writes to `partner_integration_error_logs` and does not crash the main request.
5. Removing an adapter configuration for a restaurant stops all dispatches to that adapter.
6. A JWT without `workforce:read` scope returns 403 on the workforce endpoint.

## Out of Scope (v1)
- Two-way sync with partners (partner → mellow.menu data write).
- Partner UI inside mellow.menu.
- Twilio/messaging integration (defined as a future partner type in the original spec — post-launch).
- Partner webhook push (event push to partner URLs) — v1 is pull-only via REST endpoints.

## Open Questions
1. Should workforce and CRM signals be computed on-the-fly from the primary DB, or from the `dw_orders_mv` materialized view? Recommend: materialized view for reporting queries; real-time signals from replica.
2. What is the required latency for canonical event dispatch after an order event occurs? Sub-5-second target recommended.
3. Is there an existing `Nory` or `SevenRooms` integration already in progress that this spec should be compatible with?

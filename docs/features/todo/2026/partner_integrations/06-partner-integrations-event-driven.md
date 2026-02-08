# Partner Integrations (Event-driven, Replaceable) (v1)

## Purpose
Expose mellow’s “live dining state” as a set of **event-driven, loosely coupled, replaceable** integrations.

Focus:

- You emit reliable signals.
- Partners consume signals to make decisions.
- No partner UI duplication inside mellow.

## Current State (today)

- Real-time events exist internally (ActionCable) for app UIs.
- Stripe customer payment intents exist (creation), but webhook-to-order-event mapping is not formalized.
- No first-class partner event stream exists.

Cross references:

- `docs/features/done/REALTIME_IMPLEMENTATION_STATUS.md`
- `docs/features/todo/stripe_restaurant_payments/README.md` (SaaS billing – separate)

## Scope (v1)

### Integration types

- **Stripe deepened (payments)**
  - Payment webhooks → canonical order events

- **Workforce (Nory-class)**
  - Provide: order velocity, item prep times, table occupancy duration

- **Reservations/CRM (SevenRooms-class)**
  - Provide: in-meal behaviour, order pacing, time-to-pay

- **Messaging (Twilio-class)** (later quarter, but specified here as a partner type)
  - Provide: receipts + nudges

### Architectural requirements

- All integrations are:
  - Event-driven
  - Loosely coupled (behind adapters)
  - Replaceable

## Non-goals (v1)

- No UI for partners.
- No “two-way sync” beyond identity context (initially).

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Canonical partner event stream

- GIVEN an order mutation occurs
  WHEN the system emits canonical events
  THEN an integration adapter can subscribe and receive a normalized payload.

- GIVEN the Stripe webhook receives `payment_intent.succeeded`
  WHEN the webhook is processed
  THEN a canonical order payment event is emitted and downstream adapters are invoked.

### Workforce signals

- GIVEN a restaurant has active orders
  WHEN workforce integration polling/export is requested
  THEN the system can provide:
  - orders per minute (velocity)
  - prep time estimates by item
  - table occupancy duration

### CRM signals

- GIVEN an order transitions to `billrequested`
  WHEN CRM adapter receives the event
  THEN it can infer “time-to-pay” tracking start.

## Progress Checklist

- [ ] Define canonical event payload schema for partners
- [ ] Implement integration adapter interface (`PartnerIntegrationAdapter`)
- [ ] Implement Stripe webhook mapping → canonical events
- [ ] Implement Workforce export endpoint (read-only)
- [ ] Implement CRM export endpoint (read-only)
- [ ] Add configuration per restaurant for enabling integrations
- [ ] Add observability:
  - [ ] per-adapter success/fail metrics
  - [ ] dead-letter logging

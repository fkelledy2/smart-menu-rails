---
name: Ledger.append! invalid enum values from Orchestrator
description: Payments::Orchestrator#create_and_capture_payment_intent! passes entity_type:'Ordr' and event_type:'auto_pay_captured' to Ledger.append! — both are not valid LedgerEvent enum values
type: project
---

`Payments::Orchestrator#create_and_capture_payment_intent!` (line 101–112) calls `Payments::Ledger.append!` with:
- `entity_type: 'Ordr'` — invalid; `LedgerEvent` enum only accepts `:payment_attempt`, `:refund`, `:transfer`, `:dispute`, `:payout`
- `event_type: 'auto_pay_captured'` — invalid; `LedgerEvent` enum only accepts `:created`, `:authorized`, `:captured`, `:succeeded`, `:failed`, `:refunded`, `:dispute_opened`

`Ledger.append!` rescues `ActiveRecord::RecordNotUnique` only — `ArgumentError` from an invalid enum propagates up and fails the auto-pay capture.

**Why:** Custom event type/entity was added to the orchestrator without updating the LedgerEvent enum.

**How to apply:** When calling Ledger.append!, always use values from `LedgerEvent.entity_types` and `LedgerEvent.event_types`. For auto-pay, use `entity_type: :payment_attempt` and `event_type: :captured` (or `:succeeded`).

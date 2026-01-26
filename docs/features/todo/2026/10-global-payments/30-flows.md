# 30 — Core Flows

## 1) Start payment (client → Smartmenu)
1. Client requests a payment attempt for an order.
2. Server validates:
   - order exists
   - order is payable (`billrequested` in current domain)
   - amount > 0 (tips excluded)
3. Server creates `payment_attempts` row.
4. Provider adapter creates a PSP payment object.
5. Server responds with `next_action`:
   - `redirect_url` (Checkout-like)
   - `client_secret` (SDK-like)

## 2) Payment completion (PSP → Smartmenu via webhook)
1. PSP sends webhook event(s).
2. Webhook gateway verifies signature and parses.
3. Adapter normalizes events into internal events.
4. Ledger appends normalized events.
5. Projector updates order status:
   - emit `paid`
   - emit `closed` (if full settlement)
6. UI updates via ActionCable broadcast.

## 3) Refunds (v1)
- Refunds are initiated by staff/admin.
- Refunds are full refunds only.
- Refund requests create a refund entity and then call provider adapter.
- Completion/confirmation is webhook-driven.

## 4) Disputes (v1 observe-only)
- In v1, ingest disputes webhooks and record them in ledger.
- Defer evidence submission tooling.

## 5) Dual MoR support
- For each payment attempt:
  - snapshot restaurant’s `merchant_model`
  - router selects `charge_pattern` based on:
    - merchant_model
    - provider capabilities
    - corridor constraints

## Failure / contingency
- PSP webhook delay: client should poll order/payment status.
- PSP outage: gracefully degrade to "pay at counter" (policy).

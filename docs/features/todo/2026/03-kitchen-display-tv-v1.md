# Kitchen Display (TV-Optimised) (v1)

## Purpose
Make the kitchen display a **first-class operational truth surface**:

- Large-format, glanceable, TV-optimized
- Real-time updates only (no polling)
- Supports “voice-ready visual state” (IDs visible, stable identifiers)

## Current State (today)

- A TV-optimized kitchen dashboard is already implemented.
- Uses ActionCable + `KitchenChannel` + broadcasting.
- Shows orders by status in three columns and supports one-click status changes.

Cross references:

- `docs/features/done/KITCHEN_DASHBOARD_UI.md`
- `docs/features/done/REALTIME_IMPLEMENTATION_STATUS.md`

## Gap vs 2026 roadmap

- Current dashboard is strongly aligned with the roadmap goals.
- What’s missing for the roadmap framing is mostly:
  - formalization as “the operational truth” surface
  - stronger stable identifiers for voice workflows (table codes, order IDs, participant IDs)
  - alignment with the future event-driven order state engine (when introduced)

## Scope (v1)

- Keep existing dashboard.
- Add explicit identity and UX affordances for voice + staff workflows:
  - consistent display of: `order_id`, `table_id`, optional `short_code`
  - clear states for “bill requested”, “paid”, “closed” visibility rules
- Ensure it is driven by the same canonical state as guest/staff UIs.

## Non-goals (v1)

- Kitchen staffing, assignments, or messaging.
- Expo-style bump screens.
- Inventory integration.

## Acceptance Criteria (GIVEN / WHEN / THEN)

- GIVEN the kitchen dashboard is open on a TV
  WHEN a new order is placed by a customer
  THEN the order appears without refresh and is visible within 1 second of commit.

- GIVEN the kitchen dashboard is open
  WHEN an order changes from `ordered` to `preparing`
  THEN the order card moves to the correct column without refresh.

- GIVEN an order card is visible
  WHEN staff need to reference it for voice or troubleshooting
  THEN the card displays stable identifiers:
  - `order_id`
  - `table_id` (and/or table label)
  - at least one additional stable reference (e.g., `created_at` or a human short code)

- GIVEN the customer smart menu is open for the same table
  WHEN the kitchen dashboard shows order status `ready`
  THEN the customer view reflects `ready` state consistently (same truth).

## Progress Checklist

- [ ] Audit current kitchen dashboard behavior vs roadmap requirements
- [ ] Ensure KDS shows stable identifiers clearly (order/table/participant references)
- [ ] Confirm “no polling” guarantee remains true
- [ ] Define explicit rules for which terminal states remove cards (delivered/paid/closed)
- [ ] Align broadcasting payload with unified order state model (future)
- [ ] Add smoke tests for ActionCable updates to KDS

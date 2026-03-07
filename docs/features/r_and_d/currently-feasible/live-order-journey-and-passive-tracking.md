# Live Order Journey & Passive Tracking

**Status:** Research / Strategy
**Feasibility:** Currently Feasible
**Target:** 2026+

## Vision

Guests get real-time awareness of where their food is in the fulfillment journey without needing waiter check-ins.

## Included Ideas

- Passive order tracking
- Dish leaving kitchen notifications
- “Your food is arriving” moments

## Feasible Now

- Kitchen emits status events
- ActionCable or push notifications update the guest UI
- Per-course or per-item lifecycle messaging

## Dependencies

- Reliable kitchen-side status transitions
- Notification strategy for web push and in-app updates

## Strategic Value

- Reduces guest anxiety
- Reduces staff interruption
- Makes the restaurant feel more responsive and modern

## Suggested R&D Path

- Start with in-app realtime state updates
- Add optional push notifications for key milestones
- Expand to more granular course and item-level tracking if operational data quality supports it

# Collaborative Dining Mesh

**Status:** Research / Strategy
**Feasibility:** Partially Feasible / Constrained by Current Platforms
**Target:** 2026+

## Vision

Treat nearby guest devices as a temporary dining cluster that can coordinate cart state, session presence, and split ordering with minimal server dependence.

## Included Ideas

- Phone-to-phone mesh networking
- Group ordering mesh
- Shared cart across phones
- WebRTC data channels
- Redis pubsub fallback
- Smart payment swarms

## Feasible Now

- Shared-table ordering via server-backed realtime sync
- Optional WebRTC data channels once guests are already connected
- Hybrid server + peer coordination for low-latency collaboration
- Split-bill negotiation and shared cart sync with ActionCable as the source of truth

## Constraints

- Browser-based peer discovery is weak
- WebRTC still needs signaling infrastructure
- Nearby device discovery is not broadly available to browser apps
- Fully serverless mesh reliability is poor in real restaurant environments

## Suggested R&D Path

### Phase A

- Shared cart + participant sync with server-first realtime
- Presence and participant awareness at the table

### Phase B

- WebRTC experiments for peer data channels
- Keep server-side realtime as authoritative fallback

### Phase C

- Revisit true mesh when discovery APIs improve

## Strategic Value

- Strong differentiation
- Better split-bill and multi-person ordering UX
- Potentially lower latency and lower server load over time

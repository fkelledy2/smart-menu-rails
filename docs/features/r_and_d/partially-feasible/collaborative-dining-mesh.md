# Collaborative Dining Mesh

**Status:** Draft Specification  
**Feasibility:** Partially Feasible / Constrained by Current Platforms  
**Target Window:** 2026+  
**Category:** Multi-Participant Ordering, Collaboration, Realtime Systems

## Feature Overview

Collaborative dining mesh treats multiple guest devices at the same table as a temporary collaborative cluster for shared cart state, participant awareness, split ordering, and negotiation flows.

The near-term implementation should remain server-first, with peer transport treated as an optional optimization rather than a source of truth.

## Problem Statement

Multi-person ordering is inherently collaborative, but guests often work through fragmented or duplicated flows. Current browser capabilities do not support a reliable serverless mesh for nearby devices, so the product must balance collaboration goals against platform constraints.

## Goals

- [ ] Improve shared ordering and split-bill collaboration across guest devices
- [ ] Preserve a reliable authoritative state model during collaborative interactions
- [ ] Reduce perceived latency in shared-table coordination where possible
- [ ] Keep the architecture open to stronger peer capabilities later

## Non-Goals

- [ ] Fully serverless mesh coordination in the initial implementation
- [ ] Browser-native nearby discovery dependence for critical flows
- [ ] Peer-only synchronization as the sole collaboration transport

## User Stories

- As a diner, I want everyone at the table to see and coordinate shared ordering state easily.
- As a group, I want collaborative cart and split-bill workflows that stay in sync across phones.
- As a platform architect, I want optional peer optimizations without sacrificing reliability.

## In Scope

- [ ] Shared-table ordering via server-backed realtime sync
- [ ] Participant presence and awareness at the table
- [ ] Shared cart synchronization
- [ ] Split-bill negotiation workflows
- [ ] Optional WebRTC experiments after explicit session connection

## Out of Scope

- [ ] True local mesh discovery as a dependency for core ordering
- [ ] Peer-only collaborative state with no authoritative fallback
- [ ] Implicit nearby device joining with no explicit session model

## Functional Requirements

### Collaboration Model

- [ ] The system must support shared cart and participant sync across multiple guest devices
- [ ] The authoritative state for ordering must remain server-backed in the first release
- [ ] The product should support participant awareness and collaborative actions at table scope

### Transport Strategy

- [ ] Server-first realtime transport should remain the default coordination mechanism
- [ ] Optional peer data channels may be explored only after explicit session join and signaling
- [ ] Peer transport, if used, must degrade back to server transport without breaking correctness

### Payments and Negotiation

- [ ] The collaboration model should support split-bill negotiation and coordination UX
- [ ] Collaborative payment-related flows must remain traceable and authoritative

## Technical Considerations

- [ ] Reuse ActionCable or equivalent realtime sync as the source of truth
- [ ] Keep peer experiments modular and isolated from critical domain logic
- [ ] Use explicit signaling if WebRTC is introduced
- [ ] Ensure collaborative state can be debugged across multiple participants and surfaces

## Dependencies

- [ ] Stable realtime shared-state infrastructure
- [ ] Participant identity and table membership model
- [ ] Shared cart or collaborative order payload support
- [ ] Fallback-safe transport abstraction if peer channels are tested

## Risks

- [ ] Peer transport may add complexity without enough user-visible benefit
- [ ] Browser discovery limitations constrain the mesh vision substantially
- [ ] Multi-device race conditions can reduce trust if authority is unclear

## Delivery Plan

### Phase 1: Server-First Collaboration

- [ ] Add participant awareness and shared cart synchronization
- [ ] Keep server-backed realtime authoritative
- [ ] Validate multi-device correctness under real table conditions

### Phase 2: Optional Peer Optimization

- [ ] Experiment with WebRTC after explicit session joins
- [ ] Keep server sync as authoritative fallback
- [ ] Measure whether peer channels improve latency enough to justify complexity

### Phase 3: Future Mesh Readiness

- [ ] Reassess architecture if browser discovery primitives improve
- [ ] Preserve modular transport boundaries for future local-first collaboration
- [ ] Extend collaborative flows only where correctness remains strong

## Acceptance Criteria

- [ ] Multi-device shared-table collaboration works reliably using server-first realtime
- [ ] Participant presence and shared cart state remain consistent across devices
- [ ] Optional peer experiments do not compromise authoritative correctness
- [ ] The design stays extensible for stronger future mesh capabilities

## Success Metrics

- [ ] Higher completion rate for multi-person shared ordering
- [ ] Reduced coordination friction during split or shared cart workflows
- [ ] Acceptable sync latency across guest devices
- [ ] Low rate of collaborative state conflicts or corrections

## Open Questions

- [ ] Which collaborative actions produce the most value at launch: shared cart, item claiming, or split negotiation?
- [ ] Is peer transport worth keeping if server-first realtime already meets latency expectations?
- [ ] How should participant conflict resolution be surfaced in the UX?
- [ ] What is the right boundary between collaboration convenience and operational complexity?

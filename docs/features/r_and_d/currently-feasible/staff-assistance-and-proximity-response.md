# Staff Assistance & Proximity Response

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Guest Assistance, Staff Routing, Service Operations

## Feature Overview

Staff assistance and proximity response allows guests to request help digitally and routes those requests intelligently to staff based on zone, station, role, and eventually stronger proximity signals where justified.

## Problem Statement

Guests often need help without wanting to wave down staff or wait for a check-in pass. Meanwhile, restaurants lack a consistent digital workflow for routing and measuring assistance requests efficiently.

## Goals

- [ ] Reduce guest friction when requesting staff assistance
- [ ] Route help requests to the most appropriate staff member or team
- [ ] Give restaurants visibility into service responsiveness
- [ ] Establish a foundation for richer proximity-aware staff routing later

## Non-Goals

- [ ] Native-device Bluetooth paging in the first browser-only phase
- [ ] Highly precise physical nearest-staff routing without reliable infrastructure
- [ ] Replacing all verbal or in-person service interactions

## User Stories

- As a guest, I want to request help discreetly from my phone.
- As staff, I want requests routed to the right person or zone so I can respond quickly.
- As an operator, I want measurable visibility into response time and unresolved service requests.

## In Scope

- [ ] Guest-initiated `need assistance` requests
- [ ] Staff notifications based on station or zone assignment
- [ ] Request states such as open, acknowledged, resolved, and expired
- [ ] Simple proximity approximations from role, zone, or recent activity context

## Out of Scope

- [ ] Precise nearest-device vibration routing in browser-only flows
- [ ] Mandatory native app rollout as part of phase one
- [ ] Hardware-dependent staff location tracking in the initial implementation

## Functional Requirements

### Guest Request Flow

- [ ] Guests should be able to trigger a help request from the Smart Menu experience
- [ ] Requests should support at least a small set of predefined intents such as assistance, bill, or issue reporting
- [ ] The guest should receive visible confirmation that the request was sent

### Staff Routing and Handling

- [ ] Requests should route by zone, station, or staff role in the initial release
- [ ] Staff should be able to acknowledge and resolve requests
- [ ] The system should prevent unresolved requests from disappearing silently

### Operational Visibility

- [ ] Operators should be able to measure response time and completion patterns
- [ ] The system should support escalation or rerouting if a request is not acknowledged within a threshold

## Technical Considerations

- [ ] Reuse realtime order or table communication channels where practical
- [ ] Model assistance requests as explicit domain objects or events
- [ ] Support zone- or station-based routing before any stronger proximity logic
- [ ] Keep the design compatible with future native app or hardware-based enhancements

## Dependencies

- [ ] Realtime notification support for staff surfaces
- [ ] Table and staff assignment context
- [ ] Staff-facing request handling UI
- [ ] Metrics for response and resolution timing

## Risks

- [ ] Over-alerting may cause staff notification fatigue
- [ ] Weak routing logic may create duplicate or missed responses
- [ ] Browser-only delivery may be less reliable than native notification channels

## Delivery Plan

### Phase 1: Zoned Assistance Requests

- [ ] Add guest assistance request entry point
- [ ] Route requests by station or zone
- [ ] Add acknowledgment and resolution states
- [ ] Measure response times and drop-off points

### Phase 2: Smarter Routing

- [ ] Add richer routing rules based on role and workload
- [ ] Add timeout-based rerouting or escalation
- [ ] Improve operator reporting for service responsiveness

### Phase 3: Proximity-Aware Expansion

- [ ] Evaluate whether native apps or hardware materially improve routing quality
- [ ] Introduce stronger proximity signals only if operational value justifies complexity
- [ ] Tune delivery channels and alert design to reduce fatigue

## Acceptance Criteria

- [ ] Guests can submit assistance requests from the Smart Menu flow
- [ ] Staff can receive, acknowledge, and resolve requests
- [ ] Initial routing works by zone or station without requiring native apps
- [ ] Operators can observe response-time metrics

## Success Metrics

- [ ] Reduced average time to first acknowledgment
- [ ] Reduced guest abandonment after requesting help
- [ ] Higher resolution rate within target SLA
- [ ] Acceptable staff notification acceptance and completion rate

## Open Questions

- [ ] Which assistance intents should be bundled in the first release?
- [ ] What response-time SLA should trigger escalation?
- [ ] Should assistance requests live alongside order state or as a separate service domain?
- [ ] At what scale does native or hardware-assisted routing become justified?

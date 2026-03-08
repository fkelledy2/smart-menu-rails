# Browser-Native Local Mesh Networking

**Status:** Draft Specification  
**Feasibility:** Requires External Tech Advancement  
**Target Window:** Future / TBD  
**Category:** Local Networking, Collaboration Infrastructure, Platform Watchlist

## Feature Overview

Browser-native local mesh networking would allow nearby guest devices to discover and coordinate directly through short-range browser-supported networking primitives, reducing server dependence for collaborative dining interactions.

## Problem Statement

The product vision for local-first collaborative dining is limited by current browser and operating system capabilities. Nearby peer discovery, secure trust models, and portable short-range networking are not mature enough on the web to support this reliably today.

## Goals

- [ ] Define the long-term product opportunity for browser-native local mesh networking
- [ ] Keep current collaboration architecture compatible with future peer networking
- [ ] Identify the external prerequisites required for viable adoption
- [ ] Avoid overcommitting product design to unavailable browser capabilities

## Non-Goals

- [ ] Shipping browser-native local mesh as a near-term core dependency
- [ ] Replacing server-backed realtime with speculative peer infrastructure today
- [ ] Relying on unsupported browser primitives for critical product flows

## User Stories

- As a product architect, I want current collaboration systems to stay extensible for future peer networking.
- As a diner, I would eventually benefit from lower-latency local coordination if the platform becomes viable.
- As an operator, I need collaboration reliability today even if future local-first approaches emerge later.

## In Scope

- [ ] Architectural preparation for future peer networking
- [ ] Evaluation of browser discovery, security, and permission maturity
- [ ] Server-first fallback design that can coexist with later peer transports
- [ ] Readiness criteria for revisiting the concept

## Out of Scope

- [ ] Near-term production rollout of browser-native mesh networking
- [ ] Assumptions that WebRTC alone solves discovery and trust
- [ ] Removing server mediation for critical coordination flows today

## Functional Requirements

### Future Capability Definition

- [ ] The product should define what collaboration scenarios would meaningfully benefit from native local mesh support
- [ ] The architecture should support optional peer transport insertion without rewriting core domain logic

### Current-State Fallbacks

- [ ] Server-backed realtime must remain the primary coordination model until platform capabilities materially improve
- [ ] Any peer experiment must keep explicit signaling and authoritative fallback in place

### Readiness Gates

- [ ] The initiative should define external platform milestones required before implementation is reconsidered
- [ ] Readiness should include browser support, security model maturity, portability, and UX trust implications

## Technical Considerations

- [ ] Browsers currently lack strong nearby discovery primitives
- [ ] WebRTC still requires signaling and does not solve ambient peer discovery
- [ ] Bluetooth mesh and WiFi Direct are not mainstream browser abstractions
- [ ] Security and permission models remain insufficient for broad consumer deployment

## Dependencies

- [ ] Browser-level nearby discovery support
- [ ] Portable short-range networking APIs across major platforms
- [ ] Clear security and consent models for local peer discovery
- [ ] A modular collaboration transport layer in the current app architecture

## Risks

- [ ] Platform maturity may remain stalled for an extended period
- [ ] Overdesigning for hypothetical mesh support may slow current product delivery
- [ ] Security and consent models may remain too weak for consumer trust even if APIs appear

## Readiness and Pre-Work Plan

### Architecture Preparation

- [ ] Keep current collaboration state and transport abstractions modular
- [ ] Avoid binding core workflows to assumptions about peer discovery
- [ ] Document where peer transport could be inserted safely later

### Experimental Monitoring

- [ ] Track browser and OS changes relevant to local discovery primitives
- [ ] Reassess WebRTC and related standards periodically
- [ ] Maintain a clear platform watchlist for this initiative

### Revisit Gates

- [ ] Require practical nearby discovery support across major target platforms
- [ ] Require an acceptable security and consent model
- [ ] Require clear evidence that local mesh materially improves collaboration over server-first realtime

## Acceptance Criteria

- [ ] The current product remains architecturally ready for future peer transport insertion
- [ ] There is a documented set of external blockers and revisit gates
- [ ] No near-term roadmap item depends on unavailable browser mesh primitives

## Success Metrics

- [ ] Minimal rework required if local mesh becomes viable later
- [ ] Clear decision framework for when to revisit the concept
- [ ] Stable collaboration performance today without speculative dependencies

## Open Questions

- [ ] Which user-facing collaboration scenarios would benefit enough from mesh to justify future complexity?
- [ ] What exact browser capability threshold should trigger renewed prototyping?
- [ ] Would a future mesh approach still need server authority for trust and reconciliation?
- [ ] Is native-app-only peer networking a more realistic interim path than waiting for the browser?

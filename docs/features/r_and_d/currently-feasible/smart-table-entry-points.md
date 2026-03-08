# Smart Table Entry Points

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Table Identity, Guest Onboarding, Physical Touchpoints

## Feature Overview

Smart table entry points replace QR-heavy entry flows with lower-friction physical touchpoints such as NFC-enabled table surfaces or holders that open the correct Smart Menu context instantly.

## Problem Statement

QR entry works, but it adds visible clutter, depends on camera scanning behavior, and creates unnecessary startup friction for guests who only need to open the correct table context quickly.

## Goals

- [ ] Reduce friction in opening the correct Smart Menu context
- [ ] Provide a cleaner physical table experience than QR-only flows
- [ ] Improve reliability and security of table-context handoff
- [ ] Create a stepping stone toward richer proximity-based experiences

## Non-Goals

- [ ] Eliminating QR as a fallback in the first release
- [ ] Requiring specialized table hardware beyond inexpensive tags or holders
- [ ] Broad passive presence detection without explicit user action

## User Stories

- As a guest, I want to tap my phone and open the right table context immediately.
- As a restaurant, I want cleaner and more durable table-entry mechanisms.
- As an operator, I want table identity to be secure enough to avoid accidental or malicious cross-table access.

## In Scope

- [ ] NFC tags embedded in tables or holders
- [ ] Tap-to-open deep links into Smart Menu
- [ ] Signed table identity in launch URLs
- [ ] QR fallback support during transition

## Out of Scope

- [ ] Fully passive proximity detection in the first release
- [ ] Hardware-heavy sensor deployments
- [ ] Removal of fallback entry methods before durability is proven

## Functional Requirements

### Entry Experience

- [ ] A guest should be able to open the correct Smart Menu context by tapping a supported physical touchpoint
- [ ] The entry flow should minimize intermediate screens where possible
- [ ] The system should preserve compatibility with QR and manual fallback paths

### Table Identity and Security

- [ ] Table context should be represented using signed or otherwise tamper-resistant identifiers
- [ ] The system must prevent obvious spoofing or easy modification of table identity links
- [ ] Operators should be able to rotate or invalidate table entry artifacts when required

### Operations

- [ ] The solution should support low-cost physical deployment across varied venue types
- [ ] The implementation should account for durability, replacement, and venue-specific wear patterns

## Technical Considerations

- [ ] Reuse existing Smart Menu deep-link and table context patterns where possible
- [ ] Add signed table identity or token-based validation to entry URLs
- [ ] Ensure the system can invalidate compromised entry points without broad disruption
- [ ] Support analytics for entry method, failure rate, and session start success

## Dependencies

- [ ] Smart Menu deep-link entry support
- [ ] Secure table identity scheme
- [ ] Physical NFC artifact production and placement process
- [ ] Operational tooling for rotation and replacement

## Risks

- [ ] NFC support and user familiarity vary by device and region
- [ ] Physical artifacts may be damaged, removed, or replaced incorrectly
- [ ] Table spoofing risk increases if link signing is weak

## Delivery Plan

### Phase 1: Secure NFC Entry Foundation

- [ ] Define signed table entry format
- [ ] Add NFC-compatible deep-link flow
- [ ] Preserve QR fallback and manual fallback paths
- [ ] Pilot in a small number of venues

### Phase 2: Operational Rollout

- [ ] Develop replacement and invalidation workflows for physical tags
- [ ] Measure tap-to-session start success rate
- [ ] Tune launch flow and failure recovery UX

### Phase 3: Broader Entry Strategy

- [ ] Segment rollout by venue type and traffic pattern
- [ ] Evaluate whether NFC meaningfully outperforms QR in real usage
- [ ] Extend the entry model into broader proximity-aware experiences if justified

## Acceptance Criteria

- [ ] Guests can open the correct table context via NFC touchpoint
- [ ] Table identity is protected against basic spoofing
- [ ] QR fallback remains available and reliable
- [ ] The physical rollout model is operationally maintainable

## Success Metrics

- [ ] Reduced time from arrival to menu open
- [ ] Increased session start rate compared with QR-only flows
- [ ] Lower abandonment during table entry
- [ ] Acceptable physical replacement/failure rate by venue

## Open Questions

- [ ] What is the right signed token lifetime for table identity links?
- [ ] Should NFC tags resolve directly or via a redirect layer that supports rotation and analytics?
- [ ] Which venue types get the highest benefit from NFC over QR?
- [ ] What is the cheapest durable physical form factor for deployment?

# UWB Table Detection

**Status:** Draft Specification  
**Feasibility:** Requires External Tech Advancement  
**Target Window:** Future / TBD  
**Category:** Precision Proximity, Table Identity, Hardware-Dependent Future Capability

## Feature Overview

UWB table detection would use Ultra Wideband-capable phones and table-side hardware to determine guest-to-table proximity with high precision, enabling stronger table confirmation, anti-spoofing, and more confident table-aware workflows.

## Problem Statement

Current web-compatible table identity mechanisms rely on QR, NFC, and coarse continuity heuristics. These are useful but cannot deliver precise physical confirmation. UWB could, in theory, provide a materially stronger trust signal, but browser access, device coverage, and hardware deployment are not broadly ready.

## Goals

- [ ] Define the future value of precise table proximity confirmation
- [ ] Keep current table identity flows extensible for stronger future proximity inputs
- [ ] Document the external blockers that prevent broad implementation today
- [ ] Clarify what pre-work is valuable before UWB becomes viable

## Non-Goals

- [ ] Shipping UWB-dependent table detection in current web flows
- [ ] Assuming broad UWB device availability across markets and platforms
- [ ] Replacing QR and NFC with hardware-heavy infrastructure today

## User Stories

- As a guest, I would eventually benefit from near-effortless, high-confidence table confirmation.
- As an operator, I want stronger anti-spoofing and table identity assurance if the ecosystem supports it.
- As a platform team, I want today’s table assignment model to be ready for future high-confidence proximity inputs.

## In Scope

- [ ] Future-state product definition for precise table confirmation
- [ ] Pre-work to keep current flows compatible with stronger proximity signals later
- [ ] Readiness criteria for revisiting native or hardware-assisted UWB experiments

## Out of Scope

- [ ] Broad production implementation in current browser environments
- [ ] Mandatory table-side hardware rollout in the current roadmap
- [ ] Removing existing trust anchors before UWB is broadly viable

## Functional Requirements

### Future Precision Use Cases

- [ ] The product should define which workflows would benefit most from precise proximity confirmation, such as table confirmation, delivery confirmation, or bill-splitting trust
- [ ] The architecture should allow future high-confidence proximity inputs to augment rather than replace current table identity logic initially

### Current Fallback Model

- [ ] NFC and QR should remain the current trust anchors
- [ ] The product should preserve compatibility with native-app experiments where hardware access is available

### Readiness Gates

- [ ] UWB support should not be reconsidered for broad rollout until browser or app access, hardware economics, and support coverage are materially better
- [ ] A clear revisit framework should be documented

## Technical Considerations

- [ ] UWB is not broadly exposed to browser apps today
- [ ] Device support remains uneven across platforms and markets
- [ ] Restaurants would need dedicated hardware rollout and maintenance processes
- [ ] Secure, standardized proximity APIs are not yet mainstream on the web

## Dependencies

- [ ] Widespread device-side UWB support in relevant markets
- [ ] Accessible browser or native APIs for secure proximity detection
- [ ] Restaurant-side hardware deployment model
- [ ] Existing table identity model that can accept stronger confidence signals later

## Risks

- [ ] Hardware rollout cost may be too high for many venues
- [ ] Market fragmentation may keep UWB out of mainstream adoption longer than expected
- [ ] Product planning may over-index on a magical future capability that stays niche

## Readiness and Pre-Work Plan

### Current-State Preparation

- [ ] Keep NFC and QR flows strong as present-day trust anchors
- [ ] Define product flows that would benefit from precise proximity confirmation
- [ ] Keep table identity confidence modeling extensible

### Experimental Pathways

- [ ] Consider native-app or hardware-access pilots only where justified
- [ ] Document learnings from any experimental proximity work that could generalize later

### Revisit Gates

- [ ] Require practical API access across relevant client platforms
- [ ] Require acceptable device market penetration
- [ ] Require a viable restaurant hardware deployment and support model
- [ ] Require evidence that precise proximity meaningfully improves trust or conversion over NFC/QR baselines

## Acceptance Criteria

- [ ] The current product has a documented path for integrating stronger proximity inputs later
- [ ] External blockers and revisit gates are clearly defined
- [ ] No present-day roadmap commitment depends on unavailable UWB infrastructure

## Success Metrics

- [ ] Minimal architectural rework required if UWB becomes viable later
- [ ] Clear product rationale for which flows deserve precision proximity in the future
- [ ] Strong current trust-anchor performance without dependence on UWB

## Open Questions

- [ ] Which specific guest or staff workflows would justify the cost of UWB hardware?
- [ ] Would native-only UWB experiments be useful before browser support exists?
- [ ] What precision threshold actually changes product value versus existing trust anchors?
- [ ] Could spoofing and trust gains be achieved sufficiently through cheaper alternatives first?

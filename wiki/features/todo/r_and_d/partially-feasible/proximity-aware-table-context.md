# Proximity-Aware Table Context

**Status:** Draft Specification  
**Feasibility:** Partially Feasible / Constrained by Current Platforms  
**Target Window:** 2026+  
**Category:** Table Identity, Arrival UX, Trust & Safety

## Feature Overview

Proximity-aware table context aims to infer or confirm which table a guest is physically at, reducing dependence on QR flows while increasing trust in table identity and lowering spoofing risk.

## Problem Statement

QR and manual table selection create friction and leave room for incorrect or spoofed table context. Strong proximity determination on the open web remains constrained, so the design must blend trust anchors with softer context signals.

## Goals

- [ ] Reduce dependence on QR-only table assignment flows
- [ ] Improve trust in table identity without relying on unsupported browser capabilities
- [ ] Use proximity hints to improve continuity and arrival UX
- [ ] Create a stepping stone toward stronger future proximity confirmation models

## Non-Goals

- [ ] Silent auto-assignment of table identity based on weak signals alone
- [ ] Browser-only precision positioning claims unsupported by current platforms
- [ ] Replacing explicit trust anchors in the first release

## User Stories

- As a guest, I want the system to make table confirmation faster and easier.
- As an operator, I want fewer misassigned sessions and lower table spoofing risk.
- As a platform team, I want to use proximity hints safely without overclaiming confidence.

## In Scope

- [ ] WiFi presence, prior table context, and explicit confirmation UX
- [ ] NFC or QR as trust anchors with continuity hints layered on top
- [ ] Rough proximity signals for staff or operational workflows
- [ ] Confidence scoring for table matching experiments

## Out of Scope

- [ ] Browser-only centimeter-level positioning
- [ ] Fully automatic table assignment from BLE or WiFi in general web flows
- [ ] Removing trust anchors before proximity confidence is proven

## Functional Requirements

### Trust Anchored Assignment

- [ ] The product should support NFC or QR as the primary trust anchor for table identity
- [ ] The system should support continuity checks that ask `Are you at Table X?` when confidence is suggestive but insufficient for silent assignment
- [ ] Weak proximity signals must not override explicit trusted table identity without confirmation

### Proximity Hints

- [ ] The system may use restaurant WiFi presence, prior table context, or rough BLE/native signals as advisory hints
- [ ] Confidence scoring should be supported for table-matching experiments
- [ ] Proximity hints should be usable for operational workflows even when guest-facing trust remains anchored elsewhere

### Safety and Fraud Resistance

- [ ] The design should reduce spoofing risk compared with manual or unsecured table selection
- [ ] The system should support future fraud or mismatch scoring as part of the table assignment model

## Technical Considerations

- [ ] Keep trust anchors and proximity hints separate in the architecture
- [ ] Avoid over-reliance on browser BLE or WiFi telemetry because of weak cross-platform consistency
- [ ] Use confidence-scored suggestion rather than silent certainty where signals are weak
- [ ] Keep the model extensible for native-app BLE or stronger future proximity primitives

## Dependencies

- [ ] Secure table identity anchors such as NFC or QR
- [ ] Session continuity and participant context
- [ ] Optional signal ingestion for WiFi, BLE, or venue-side context where available
- [ ] UX for confirmation and mismatch correction

## Risks

- [ ] Weak signals may produce incorrect table suggestions
- [ ] Permission-heavy BLE approaches may reduce adoption or trust
- [ ] Overclaiming proximity confidence could damage product credibility

## Delivery Plan

### Phase 1: Anchored Continuity

- [ ] Strengthen NFC / QR anchored table identity
- [ ] Add continuity checks and confirmation prompts
- [ ] Measure whether guided confirmation reduces misassignment and friction

### Phase 2: Confidence-Scored Experiments

- [ ] Add confidence scoring for proximity-based table suggestions
- [ ] Test native-app or BLE-assisted experiments only where feasible
- [ ] Introduce mismatch/fraud heuristics for auditing and tuning

### Phase 3: Stronger Proximity Readiness

- [ ] Preserve extensibility toward stronger proximity technologies such as UWB
- [ ] Define how proximity confidence could evolve without breaking trust anchors
- [ ] Reassess removal of QR dependence only after confidence and reliability improve materially

## Acceptance Criteria

- [ ] Guests can confirm the correct table faster than with manual selection alone
- [ ] Trusted anchors remain primary while proximity hints improve continuity
- [ ] The design reduces spoofing risk compared with weaker table assignment flows
- [ ] The system remains honest about confidence limits under current platform constraints

## Success Metrics

- [ ] Reduced table misassignment rate
- [ ] Reduced arrival-to-table-confirmation time
- [ ] Lower spoofing or correction incidence
- [ ] Positive guest acceptance of suggested-table confirmation UX

## Open Questions

- [ ] Which continuity signals are strong enough to suggest but not assign a table?
- [ ] What confidence threshold should trigger a proactive `Are you at Table X?` prompt?
- [ ] Which parts of proximity logic are worth testing in native-only pilots?
- [ ] How should fraud scoring interact with explicit table confirmation?

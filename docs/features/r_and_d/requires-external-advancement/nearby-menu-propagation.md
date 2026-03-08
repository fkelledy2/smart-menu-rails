# Nearby Menu Propagation

**Status:** Draft Specification  
**Feasibility:** Requires External Tech Advancement  
**Target Window:** Future / TBD  
**Category:** Session Growth, Nearby Discovery, Collaborative Onboarding

## Feature Overview

Nearby menu propagation would allow one guest opening a menu to trigger nearby join prompts for other devices in physical proximity, creating a low-friction collaborative table onboarding experience.

## Problem Statement

Group ordering setup still requires explicit invitation, QR, or NFC steps. Automatic nearby discovery and invitation could reduce friction, but current browser and OS ecosystems do not expose the necessary portable primitives with acceptable trust and consent models.

## Goals

- [ ] Define the future opportunity for passive or semi-passive nearby table-session joining
- [ ] Keep current group onboarding flows extensible for future discovery-based joining
- [ ] Build strong explicit-invite alternatives today
- [ ] Document external blockers and revisit thresholds clearly

## Non-Goals

- [ ] Shipping passive nearby join prompts in the browser today
- [ ] Replacing QR, NFC, or explicit share links before discovery primitives exist
- [ ] Assuming OS-level sharing ecosystems will become portable enough without evidence

## User Stories

- As a diner, I would eventually benefit from effortless group onboarding if nearby joining becomes trustworthy.
- As a table organizer, I want everyone else to join the same session with minimal setup.
- As a product team, I want today’s invite model to be compatible with future nearby discovery.

## In Scope

- [ ] Readiness planning for future nearby join prompts
- [ ] Improvement of explicit invite alternatives available today
- [ ] Architectural preparation for layered discovery if platform support improves

## Out of Scope

- [ ] Production passive table-session discovery in current browser environments
- [ ] Implicit joining without user consent
- [ ] Dependence on proprietary OS features that cannot support a portable web product

## Functional Requirements

### Future Discovery Model

- [ ] The product should define what a trustworthy nearby join prompt would require in terms of consent, context, and table confidence
- [ ] The system should remain able to attach future discovery signals to the existing participant-join model

### Current Alternatives

- [ ] Explicit share-link invites should remain a first-class onboarding mechanism
- [ ] QR, NFC, and server-mediated invites should continue to cover the current use case safely

### Readiness Gates

- [ ] The concept should not move toward implementation until nearby discovery, trust, and consent are viable across target platforms
- [ ] A clear set of revisit criteria should be documented

## Technical Considerations

- [ ] Nearby device discovery is not broadly available to browser apps today
- [ ] Trust and consent in shared physical spaces are nontrivial product design problems
- [ ] OS-level sharing systems are not open enough for a portable web implementation
- [ ] Current collaboration flows should remain modular enough to accept future discovery layers

## Dependencies

- [ ] Browser or OS support for nearby discovery
- [ ] Strong trust and consent model for shared physical contexts
- [ ] Existing explicit invite architecture that can accept future layering

## Risks

- [ ] Passive discovery may feel intrusive even if technically feasible later
- [ ] Proximity without strong trust anchors may increase accidental or malicious joins
- [ ] Overinvesting in speculative propagation could distract from explicit invite improvements that work now

## Readiness and Pre-Work Plan

### Current-State Improvements

- [ ] Improve share-link based invite flows
- [ ] Continue using QR, NFC, and server-mediated participant invites
- [ ] Reduce friction in explicit onboarding paths as much as possible

### Architecture Readiness

- [ ] Keep participant join and session membership models extensible
- [ ] Document where nearby discovery signals could plug into current flows
- [ ] Preserve explicit consent checkpoints in any future design

### Revisit Gates

- [ ] Require platform support for nearby discovery across major target environments
- [ ] Require a trustworthy join-confirmation and consent UX model
- [ ] Require clear evidence that propagation improves onboarding enough to justify risk and complexity

## Acceptance Criteria

- [ ] Current invite flows are positioned as the durable baseline
- [ ] The concept is documented with clear blockers and future readiness gates
- [ ] No current implementation depends on unavailable nearby discovery primitives

## Success Metrics

- [ ] Lower friction in explicit group onboarding flows today
- [ ] Minimal rework required if nearby propagation becomes viable later
- [ ] Clear internal decision framework for when to revisit the concept

## Open Questions

- [ ] What level of proximity confidence would be required before showing a nearby join prompt?
- [ ] Should future propagation always require explicit acceptance from the joining device?
- [ ] Would venue context or trust anchors still be required even if discovery improves?
- [ ] Are there native or hybrid interim paths worth considering before browser support exists?

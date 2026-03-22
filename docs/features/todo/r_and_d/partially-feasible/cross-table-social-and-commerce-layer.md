# Cross-Table Social & Commerce Layer

**Status:** Draft Specification  
**Feasibility:** Partially Feasible / Constrained by Current Platforms  
**Target Window:** 2026+  
**Category:** Social Commerce, Hospitality Experiences, Venue Participation

## Feature Overview

The cross-table social and commerce layer enables tables to interact through moderated, venue-appropriate experiences such as gifting, voting, and participatory prompts that make the dining room feel more social and alive.

## Problem Statement

Most digital dining systems stop at the individual table. This misses opportunities for hospitality-led social moments, event participation, and new revenue mechanics in venues where communal energy is part of the experience.

## Goals

- [ ] Enable safe, venue-appropriate cross-table interactions
- [ ] Create new hospitality and commerce mechanics such as gifting and participation
- [ ] Preserve staff control and abuse prevention in socially sensitive flows
- [ ] Keep this layer optional and venue-dependent rather than a core ordering dependency

## Non-Goals

- [ ] Making cross-table interaction mandatory for ordinary dining flows
- [ ] Allowing anonymous or unmoderated social transactions by default
- [ ] Shipping social mechanics that conflict with venue tone or service model

## User Stories

- As a guest, I want social participation features that fit the venue atmosphere.
- As staff, I want visibility and control over cross-table gifting or prompts.
- As an operator, I want new experiential and revenue mechanics without opening abuse vectors.

## In Scope

- [ ] Server-mediated gifting between tables
- [ ] Live polls and restaurant-wide participation moments
- [ ] Table-targeted payment or gifting flows with staff approval
- [ ] Venue-configurable social prompts or moments

## Out of Scope

- [ ] Unmoderated social commerce between unknown tables
- [ ] Core ordering dependence on cross-table interaction
- [ ] One-size-fits-all rollout across every venue type

## Functional Requirements

### Interaction Types

- [ ] The system should support a small set of moderated cross-table interaction types such as gifting or polls
- [ ] Venue operators should be able to opt in to supported interaction modes
- [ ] Staff approval should be supported for higher-risk interactions such as inter-table gifting

### Trust and Moderation

- [ ] Table addressing must be trustworthy enough to prevent misdelivery
- [ ] Abuse prevention controls must exist for spam, harassment, or accidental misuse
- [ ] Social features should be suppressible by venue or event context

### Experience Design

- [ ] The social layer should fit hospitality-led venues better than quiet or private dining formats
- [ ] Social moments should feel additive, not disruptive to core ordering flows

## Technical Considerations

- [ ] Reuse table identity, payment approval, and realtime messaging infrastructure where possible
- [ ] Ensure inter-table actions are auditable and attributable at the table level
- [ ] Keep social interactions modular so they can be enabled per venue type or event mode

## Dependencies

- [ ] Trustworthy table identity
- [ ] Staff approval workflows for higher-risk actions
- [ ] Abuse prevention and rate limiting
- [ ] Realtime delivery for live prompts and participation moments

## Risks

- [ ] Social mechanics may feel off-brand in the wrong venue context
- [ ] Abuse prevention may be more complex than the novelty justifies
- [ ] Misaddressed gifting or participation could create poor guest experiences

## Delivery Plan

### Phase 1: Moderated Participation

- [ ] Add opt-in live polls or participation moments
- [ ] Restrict rollout to venues with clear hospitality or event fit
- [ ] Measure engagement and operational burden

### Phase 2: Staff-Approved Gifting

- [ ] Add inter-table gifting with explicit staff approval
- [ ] Introduce table-targeted payment and fulfillment checks
- [ ] Add moderation and abuse reporting controls

### Phase 3: Venue-Specific Expansion

- [ ] Expand interaction types only where strong venue fit exists
- [ ] Add operator controls for social intensity and enabled mechanics
- [ ] Tune the system by venue category and event format

## Acceptance Criteria

- [ ] Social interactions can be enabled per venue without affecting core ordering flows
- [ ] Higher-risk interactions support approval and abuse controls
- [ ] The system can deliver participation moments in realtime
- [ ] The feature is operationally safe in pilot venues

## Success Metrics

- [ ] Participation rate in enabled social experiences
- [ ] Revenue or attach-rate impact from gifting mechanics
- [ ] Low abuse and moderation incident rate
- [ ] Positive venue fit and staff feedback in pilots

## Open Questions

- [ ] Which venues are appropriate for the first pilot?
- [ ] What abuse vectors are most likely in inter-table gifting?
- [ ] Should all gifting require staff approval, or only above certain thresholds?
- [ ] Which social mechanics create delight without undermining brand tone?

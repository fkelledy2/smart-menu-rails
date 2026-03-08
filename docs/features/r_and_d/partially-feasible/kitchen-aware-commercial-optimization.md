# Kitchen-Aware Commercial Optimization

**Status:** Draft Specification  
**Feasibility:** Partially Feasible / Constrained by Current Platforms  
**Target Window:** 2026+  
**Category:** Operations, Merchandising, Commercial Control

## Feature Overview

Kitchen-aware commercial optimization uses kitchen-state signals to influence demand through ranking, promotion, availability messaging, and, in tightly constrained cases, pricing experiments.

## Problem Statement

Restaurants often have no live mechanism to steer demand away from overloaded stations or toward faster, more operationally efficient items. At the same time, aggressive commercial controls such as dynamic pricing can create trust and reputational risks if handled poorly.

## Goals

- [ ] Help restaurants steer demand based on real kitchen conditions
- [ ] Improve throughput and operational flow during busy periods
- [ ] Start with soft commercial controls before price changes
- [ ] Preserve guest trust through explainable and bounded interventions

## Non-Goals

- [ ] Broad dynamic pricing rollout in the first phase
- [ ] Opaque demand steering that guests cannot understand
- [ ] Commercial logic that overrides core hospitality values

## User Stories

- As an operator, I want the menu to help the kitchen by steering guests toward feasible items.
- As a guest, I want recommendations or availability cues that reflect current reality without feeling manipulative.
- As a product owner, I want commercial optimization that improves operations without damaging trust.

## In Scope

- [ ] Ranking changes based on kitchen load
- [ ] Promotion of quick-prep or low-pressure dishes
- [ ] Limited availability or surge-friction labels
- [ ] Narrow, explicit experiments around price adjustment only if justified

## Out of Scope

- [ ] Broad always-on dynamic pricing for the menu
- [ ] Hidden or deceptive pricing changes
- [ ] Unbounded algorithmic reprioritization without operator visibility

## Functional Requirements

### Soft Demand Steering

- [ ] The system should support ranking changes based on trustworthy kitchen-state inputs
- [ ] The system should support promotion of quicker or less constrained dishes
- [ ] The UI should support explainability labels such as `Fastest from kitchen right now`

### Availability and Friction

- [ ] The system should support limited-availability messaging when stations are overloaded
- [ ] Commercial controls should prefer friction and messaging over price changes in early phases

### Pricing Controls

- [ ] Any pricing experiment must be narrow, explicit, and operator-controlled
- [ ] Pricing changes must be measurable, reversible, and bounded by clear rules

## Technical Considerations

- [ ] Reuse kitchen-state and menu ranking inputs where possible
- [ ] Separate demand steering logic from canonical menu pricing data where feasible
- [ ] Instrument guest response and kitchen impact separately
- [ ] Ensure all commercial interventions can be disabled quickly

## Dependencies

- [ ] Trustworthy kitchen-state inputs
- [ ] Ranking and merchandising control layer
- [ ] Explainability support in Smart Menu payloads
- [ ] Experimentation and rollback controls

## Risks

- [ ] Dynamic pricing can create reputational damage if not clearly framed
- [ ] Weak kitchen signals may produce counterproductive steering
- [ ] Restaurants may reject interventions that feel too commercial or too automated

## Delivery Plan

### Phase 1: Ranking and Messaging

- [ ] Add kitchen-aware ranking shifts
- [ ] Add quick-prep and low-pressure highlight labels
- [ ] Measure operational and commercial impact without changing prices

### Phase 2: Friction Controls

- [ ] Introduce limited availability or surge-friction messaging
- [ ] Tune thresholds by station type and service style
- [ ] Add operator visibility into why steering is occurring

### Phase 3: Narrow Pricing Experiments

- [ ] Define explicit rules and cohorts for any price-related experiment
- [ ] Run controlled tests only where restaurant partners opt in knowingly
- [ ] Evaluate trust, margin, and throughput outcomes before any expansion

## Acceptance Criteria

- [ ] The product can steer demand using ranking and messaging based on kitchen conditions
- [ ] Soft controls improve throughput or reduce pressure in measurable ways
- [ ] Any pricing experimentation remains explicit, bounded, and reversible
- [ ] Guest trust is preserved through explainable interventions

## Success Metrics

- [ ] Reduced overload on constrained stations
- [ ] Improved throughput during peak periods
- [ ] Higher selection of promoted low-pressure items
- [ ] Acceptable guest trust and complaint rates during experiments

## Open Questions

- [ ] Which kitchen signals are reliable enough to drive guest-facing steering?
- [ ] What forms of friction feel helpful rather than punitive?
- [ ] Under what circumstances, if any, should price change be considered acceptable?
- [ ] How should operators configure or override steering rules in real time?

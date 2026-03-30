# Social Dining Intelligence

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Social Proof, Discovery, Realtime Merchandising

## Feature Overview

Social dining intelligence surfaces privacy-safe table-level and restaurant-level social signals such as trending items, freshness moments, and anonymous co-order patterns to improve confidence, discovery, and delight.

## Problem Statement

Guests often make decisions with little confidence about what is popular, fresh, or socially validated. Static menus miss the opportunity to use live restaurant activity to guide discovery in a trustworthy way.

## Goals

- [ ] Increase guest confidence through privacy-safe social proof
- [ ] Improve discovery of relevant and high-margin items
- [ ] Make the menu feel dynamic and alive without violating privacy expectations
- [ ] Reuse live restaurant and kitchen signals to enrich the guest experience

## Non-Goals

- [ ] Exposing identifiable individual choices
- [ ] Sharing personal dining behavior across tables
- [ ] Social proof that is misleading, manipulative, or too sparse to be trustworthy

## User Stories

- As a guest, I want to know what is trending or freshly available so I can choose with more confidence.
- As a guest, I want social cues that are useful without feeling invasive.
- As a restaurant, I want social proof modules that help discovery and conversion safely.

## In Scope

- [ ] Trending tonight modules
- [ ] Privacy-safe `people at this table ordered this` moments
- [ ] Kitchen freshness or limited-availability highlights
- [ ] Cross-table aggregate social proof widgets

## Out of Scope

- [ ] Personally identifiable or table-identifiable disclosure
- [ ] Social modules that reveal a single diner’s behavior
- [ ] Cross-restaurant social proof without strong normalization and privacy controls

## Functional Requirements

### Social Signals

- [ ] The system should support restaurant-level trending signals based on recent order streams
- [ ] The system may support table-level aggregate cues only when minimum thresholds prevent singling out individuals
- [ ] The system should support freshness or newly-available moments originating from kitchen or inventory events

### Privacy and Thresholding

- [ ] Table-level social proof must require minimum aggregation thresholds
- [ ] The product must not reveal individual diner choices directly
- [ ] Social proof should degrade gracefully when thresholds are not met

### Presentation

- [ ] Social signals should be presented as optional menu modules or inline badges
- [ ] The UX should distinguish between trending, fresh, and table-context signals

## Technical Considerations

- [ ] Reuse order stream and kitchen event inputs for live signal generation
- [ ] Define thresholding logic for privacy-safe aggregate displays
- [ ] Ensure social proof modules can be projected into Smart Menu state without excessive churn
- [ ] Instrument impressions, interactions, and conversion impact by signal type

## Dependencies

- [ ] Reliable recent order stream access
- [ ] Kitchen freshness or limited-availability events
- [ ] Aggregation and threshold logic
- [ ] Smart Menu support for social proof modules or badges

## Risks

- [ ] Weak thresholding could expose overly specific behavior
- [ ] Social proof may bias guests too heavily toward already-popular items
- [ ] Low-volume restaurants may not have enough data for compelling signals

## Delivery Plan

### Phase 1: Anonymous Aggregate Signals

- [ ] Add restaurant-level trending modules
- [ ] Define privacy thresholds for any table-adjacent messaging
- [ ] Measure guest interaction and conversion impact

### Phase 2: Freshness and Realtime Moments

- [ ] Add kitchen-originated freshness or just-made signals
- [ ] Add limited-availability cues where operationally reliable
- [ ] Tune presentation language for trust and clarity

### Phase 3: Optimization and Expansion

- [ ] Evaluate which social proof surfaces drive the best discovery outcomes
- [ ] Tune thresholds and suppression logic by restaurant type
- [ ] Expand richer social modules only where privacy and data volume allow

## Acceptance Criteria

- [ ] Social proof modules are privacy-safe and thresholded
- [ ] Trending and freshness signals can be surfaced from live restaurant data
- [ ] Social modules improve discovery without exposing individuals
- [ ] The system degrades gracefully when insufficient signal exists

## Success Metrics

- [ ] Increased CTR on social proof modules
- [ ] Higher attach rate for socially surfaced items
- [ ] Improved guest exploration depth
- [ ] Low privacy complaint rate

## Open Questions

- [ ] What threshold should be required before showing any table-level aggregate signal?
- [ ] Which wording best balances excitement with trust?
- [ ] Should freshness signals be manual, kitchen-driven, or automatically inferred?
- [ ] How should low-volume restaurants participate without misleading guests?

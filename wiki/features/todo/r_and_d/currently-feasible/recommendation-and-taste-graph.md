# Recommendation & Taste Graph

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Recommendations, Personalization, Merchandising

## Feature Overview

The recommendation and taste graph builds collaborative filtering and graph-based recommendation systems from real dining behavior, enabling contextual suggestions such as `People who ordered this also ordered...`, pairing expansion, and restaurant-specific discovery.

## Problem Statement

Menus often rely on static merchandising and hand-authored recommendations. This limits discovery and fails to capitalize on real co-ordering behavior, pairing patterns, and repeat session signals.

## Goals

- [ ] Increase discovery of relevant adjacent items
- [ ] Improve conversion and average spend through data-backed recommendations
- [ ] Build a durable recommendation layer that compounds with usage over time
- [ ] Support both restaurant-specific and privacy-safe broader recommendation models

## Non-Goals

- [ ] Black-box recommendations with no evaluation controls
- [ ] Cross-tenant leakage of sensitive restaurant behavior
- [ ] One-size-fits-all ranking with no restaurant-level nuance

## User Stories

- As a guest, I want relevant item suggestions based on what people commonly order together.
- As a restaurant, I want recommendations that help guests discover pairings and complementary items.
- As a product owner, I want a reusable recommendation layer that improves with scale.

## In Scope

- [ ] Co-order recommendations
- [ ] Co-view and session-based recommendations
- [ ] Pairing graph expansion for drinks, desserts, and sides
- [ ] Restaurant-specific recommendation layers
- [ ] Privacy-safe network-wide pattern transfer where appropriate

## Out of Scope

- [ ] Unbounded cross-tenant recommendation sharing
- [ ] High-risk personalization based on sensitive user traits
- [ ] Recommendations that override explicit restaurant merchandising priorities without controls

## Functional Requirements

### Recommendation Types

- [ ] The system must support recommendations derived from item co-occurrence in real orders
- [ ] The system should support session-based recommendations from views and interactions where available
- [ ] The system should support pairing graph expansion for relevant item categories

### Relevance and Controls

- [ ] Recommendations must be measurable, tuneable, and disableable
- [ ] Restaurant-specific recommendation layers should be preferred where sufficient signal exists
- [ ] The system must support fallbacks when local data volume is too low

### Presentation

- [ ] Recommendations should support explainable placement such as `Often ordered together`
- [ ] Recommendation modules should fit into existing Smart Menu layouts without creating a separate browsing paradigm

## Technical Considerations

- [ ] Build recommendation candidates from order co-occurrence and session data
- [ ] Maintain separation between tenant-specific models and broader aggregate layers
- [ ] Support offline computation and lightweight runtime retrieval
- [ ] Provide an experimentation surface for ranking strategy comparisons

## Dependencies

- [ ] Reliable order event or order history data
- [ ] Candidate generation and ranking infrastructure
- [ ] Privacy-safe aggregation rules
- [ ] Smart Menu placement support for recommendation widgets

## Risks

- [ ] Sparse restaurant data may produce weak early recommendations
- [ ] Poorly tuned cross-restaurant transfer may reduce relevance
- [ ] Recommendations may overweight popularity at the expense of exploration or margin

## Delivery Plan

### Phase 1: Co-Occurrence Foundation

- [ ] Build co-order recommendation generation
- [ ] Add basic `often ordered together` modules
- [ ] Instrument impression, click, and conversion metrics

### Phase 2: Graph Expansion

- [ ] Add co-view and session-based recommendations
- [ ] Expand graph logic into drinks, desserts, and sides
- [ ] Tune ranking based on restaurant context and performance

### Phase 3: Scaled Recommendation Layer

- [ ] Add privacy-safe fallback layers for sparse restaurants
- [ ] Compare restaurant-specific versus broader models
- [ ] Introduce controls for merchandising blend and exploration rate

## Acceptance Criteria

- [ ] Recommendation modules can be generated from real usage data
- [ ] Restaurants with sufficient data receive relevant local recommendations
- [ ] Sparse restaurants degrade gracefully using safe fallback logic
- [ ] Recommendation effectiveness can be measured through conversion metrics

## Success Metrics

- [ ] Increased attach rate for recommended items
- [ ] Improved average order value
- [ ] Higher discovery rate for secondary items and pairings
- [ ] Positive CTR-to-conversion ratio for recommendation modules

## Open Questions

- [ ] What data volume threshold should switch between restaurant-specific and fallback models?
- [ ] How should margin, popularity, and relevance be balanced in ranking?
- [ ] Which recommendation surfaces are most valuable: PDP, cart, table state, or search?
- [ ] What privacy model is acceptable for broader taste graph reuse across restaurants?

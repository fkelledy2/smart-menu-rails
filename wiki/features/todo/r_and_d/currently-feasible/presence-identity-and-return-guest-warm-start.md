# Presence, Identity & Return-Guest Warm Start

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Session Intelligence, Personalization, Performance

## Feature Overview

Presence, identity, and return-guest warm start aims to make repeat visits feel faster and more contextual by preloading menu and session context when the system has privacy-safe signals that a guest is likely returning.

The first implementation should emphasize performance warm-start behavior and explicit consent, not silent identity assumptions.

## Problem Statement

Returning guests often repeat the same startup steps every visit: opening the menu, waiting for initial load, re-entering preferences, and rediscovering familiar paths. This creates avoidable friction at the beginning of a dining session.

## Goals

- [ ] Reduce startup friction for returning guests
- [ ] Preload likely-relevant session context safely and transparently
- [ ] Support later personalization layers with trustworthy identity signals
- [ ] Preserve guest comfort by making opt-in and assumptions explicit

## Non-Goals

- [ ] Silent or invasive identity inference in the first release
- [ ] Cross-venue tracking without clear product justification and consent
- [ ] High-risk personalization based on sensitive attributes
- [ ] Persistent identity assumptions that the guest cannot inspect or control

## User Stories

- As a returning guest, I want the menu to feel ready faster when I revisit a venue.
- As a returning guest, I want the product to remember helpful context only when I have opted in.
- As an operator, I want repeat visits to feel smoother without creating privacy discomfort.

## In Scope

- [ ] Logged-in session recall
- [ ] Returning-device heuristics with consent
- [ ] Warm-start performance preloading
- [ ] Venue-entry hints based on active session behavior
- [ ] Explicit preference restoration when permitted

## Out of Scope

- [ ] Hidden identity resolution with no guest-facing explanation
- [ ] Fine-grained background tracking beyond the restaurant context
- [ ] Automatic application of preferences without user visibility in the first release

## Functional Requirements

### Warm Start and Recall

- [ ] The system should support a fast-start path for returning guests with valid consent signals
- [ ] Warm start may preload menu shell, likely locale, and previously selected non-sensitive preferences
- [ ] Logged-in recall and device-based recall should be handled separately and explicitly

### Consent and Trust

- [ ] Persistent return-guest behavior must require explicit opt-in when identity is retained across sessions
- [ ] The product must provide clear controls to disable remembered context
- [ ] The guest experience should prefer helpful preload behavior over strong identity claims

### Personalization Boundaries

- [ ] The first release should focus on performance and continuity rather than deep personalization
- [ ] Any use of remembered preferences should be user-visible and reversible

## Technical Considerations

- [ ] Reuse existing session, locale, and participant identification patterns where available
- [ ] Separate ephemeral session context from persistent return-guest context
- [ ] Ensure remembered context can be invalidated or expired cleanly
- [ ] Capture consent state and warm-start source for auditing and analytics

## Dependencies

- [ ] Reliable session and device-level recall primitives
- [ ] Preference storage with clear consent boundaries
- [ ] Performance preload mechanisms
- [ ] UI affordances for opt-in, review, and opt-out

## Risks

- [ ] Guests may perceive the feature as creepy if assumptions are too strong
- [ ] Weak device heuristics may create incorrect warm starts
- [ ] Persistent identity handling may introduce privacy and compliance burdens

## Delivery Plan

### Phase 1: Performance Warm Start

- [ ] Implement preload-oriented fast start for repeat sessions
- [ ] Restore low-risk context such as locale and recent venue state where appropriate
- [ ] Measure startup latency improvements for returning sessions

### Phase 2: Consent-Based Recall

- [ ] Add explicit opt-in for persistent return-guest behavior
- [ ] Support remembered non-sensitive preferences with visible controls
- [ ] Add analytics for opt-in, usage, and opt-out behavior

### Phase 3: Trustworthy Personalization Expansion

- [ ] Introduce richer repeat-guest continuity only where trust signals are strong
- [ ] Tune heuristics and messaging for comfort and clarity
- [ ] Define safe boundaries for future personalization layers

## Acceptance Criteria

- [ ] Repeat sessions can start faster than cold sessions
- [ ] Any persistent return-guest behavior is opt-in and reversible
- [ ] Warm-start behavior does not over-assert identity when confidence is low
- [ ] The experience feels helpful without surprising the guest

## Success Metrics

- [ ] Reduced time-to-interactive for returning guests
- [ ] Increased repeat-session completion and order-start rate
- [ ] Opt-in rate for remembered context
- [ ] Low discomfort or privacy complaint rate

## Open Questions

- [ ] What should count as low-risk context for preload by default?
- [ ] Should venue-entry hints come only from active in-product behavior, or also from physical touchpoints such as NFC?
- [ ] How long should remembered context persist before expiration?
- [ ] What is the minimum consent UX needed before expanding beyond performance warm start?

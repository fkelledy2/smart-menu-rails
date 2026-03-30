# Ambient Sensing & Restaurant State Detection

**Status:** Draft Specification  
**Feasibility:** Partially Feasible / Constrained by Current Platforms  
**Target Window:** 2026+  
**Category:** Context Sensing, Adaptive UX, Operational Intelligence

## Feature Overview

Ambient sensing and restaurant state detection uses device and environmental signals, or privacy-safe proxies for those signals, to adapt interface density, pacing, and service recommendations to the real operating context of a venue.

## Problem Statement

Restaurant environments vary widely by noise, lighting, crowd pressure, pace, and attentional load. Static interfaces cannot respond to these conditions, which limits usability in loud, rushed, or low-attention situations.

## Goals

- [ ] Improve usability by adapting UI behavior to restaurant context
- [ ] Prefer low-risk inferred context before requesting sensitive sensor access
- [ ] Support context-aware recommendations and pacing without relying on invasive sensing
- [ ] Create a richer context layer for later adaptive and personalized features

## Non-Goals

- [ ] Continuous raw-sensor surveillance of guests
- [ ] Background sensing that depends on unsupported browser capabilities
- [ ] Sensor-heavy strategies with weak user-facing value explanation

## User Stories

- As a guest, I want the interface to feel easier to use in noisy or rushed situations.
- As an operator, I want digital experiences that fit the tone and conditions of service.
- As a product team, I want a context layer that can improve UX without crossing privacy boundaries.

## In Scope

- [ ] Time-based and business-state heuristics as ambient proxies
- [ ] Opt-in microphone-based noise estimation in narrow flows
- [ ] Presence heuristics from sessions or venue infrastructure where available
- [ ] UI density and pacing adaptation based on inferred state

## Out of Scope

- [ ] Continuous camera-driven environmental analysis in browser flows
- [ ] Passive background sensing unsupported by modern web permission models
- [ ] High-confidence auto-detection claims where signals are weak or inconsistent

## Functional Requirements

### Context Inputs

- [ ] The system should support business-state and time-based proxies as the default context layer
- [ ] Explicit sensor access should only be requested when the user benefit is clear and immediate
- [ ] Device or venue signals should be treated as advisory unless confidence is high

### UX Adaptation

- [ ] The interface should support adaptation of density, pacing, and messaging based on ambient context
- [ ] The product should be able to switch between calmer and higher-speed interface modes where appropriate
- [ ] Adaptation must remain reversible and understandable rather than surprising

### Privacy and Permissions

- [ ] The design must minimize sensitive permission requests
- [ ] Sensor-dependent features must degrade gracefully when access is denied or unavailable

## Technical Considerations

- [ ] Prefer inferred operational context over raw sensor capture
- [ ] Separate durable operational signals from noisy client-side sensor hints
- [ ] Capture confidence levels for sensor-derived assumptions
- [ ] Ensure context can be projected into Smart Menu state without overcomplicating the runtime

## Dependencies

- [ ] Reliable business-state and venue-context heuristics
- [ ] Permission-aware client UX for any sensor access
- [ ] UI support for density and pace adaptation
- [ ] Analytics to measure whether context adaptation improves outcomes

## Risks

- [ ] Sensor permissions are sensitive and can damage trust if overused
- [ ] Ambient light, temperature, and environmental data remain inconsistent across devices
- [ ] Weak context inference may cause the wrong UX mode to appear

## Delivery Plan

### Phase 1: Proxy-Driven Context

- [ ] Implement time-based and business-state heuristics
- [ ] Add adaptive UI density and pacing modes driven by safe proxies
- [ ] Measure usability impact before introducing sensors

### Phase 2: Narrow Sensor Experiments

- [ ] Test opt-in microphone-based noise estimation in limited flows
- [ ] Add confidence-scored use of venue or presence hints
- [ ] Compare proxy-only versus sensor-assisted outcomes

### Phase 3: Controlled Expansion

- [ ] Expand only the sensing approaches that show clear value and acceptable trust outcomes
- [ ] Tune adaptation logic by venue type and service style
- [ ] Document privacy boundaries for future context features

## Acceptance Criteria

- [ ] Context-aware UI changes can be driven without requiring invasive sensing
- [ ] Sensor-dependent enhancements remain optional and permission-aware
- [ ] The interface improves fit-to-context in at least one measurable scenario
- [ ] The feature degrades gracefully when signals are weak or absent

## Success Metrics

- [ ] Improved engagement or completion in noisy or rushed conditions
- [ ] Reduced friction in high-attention-cost environments
- [ ] Low sensor permission rejection or discomfort rate
- [ ] Positive usability feedback for adaptive presentation modes

## Open Questions

- [ ] Which ambient conditions are best inferred indirectly versus sensed explicitly?
- [ ] What contexts justify explicit sensor access strongly enough to ask for permission?
- [ ] How should the product communicate ambient adaptation to avoid surprise?
- [ ] Which venue types benefit most from pace and density adaptation?

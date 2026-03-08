# Distributed Restaurant Operating Surface

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Platform Architecture, Staff Operations, Guest Experience

## Feature Overview

The distributed restaurant operating surface turns Smart Menu into a shared operating substrate used by guests, staff, and operational systems across phones, tablets, and other lightweight endpoints.

Rather than building separate products for guest ordering, staff handheld workflows, table coordination, and kitchen awareness, this initiative aligns them around shared order, table, and event models.

## Problem Statement

Restaurants often operate across fragmented surfaces: guest ordering flows, staff tools, kitchen systems, and ad hoc coordination channels. This increases operational latency, data inconsistency, and UI duplication.

## Goals

- [ ] Unify guest and staff interactions around the same canonical order and table state
- [ ] Reduce duplication between customer and staff interface logic
- [ ] Support staff handheld workflows on the existing web stack
- [ ] Strengthen the platform’s position as a restaurant floor operating system

## Non-Goals

- [ ] Replacing every external POS workflow in the first phase
- [ ] Shipping a dedicated hardware strategy as part of the initial rollout
- [ ] Fully collapsing guest and staff UX into one identical interface

## User Stories

- As staff, I want handheld workflows built on the same live order state guests see so coordination is simpler.
- As an operator, I want table, order, and kitchen actions to stay in sync across all devices.
- As a guest, I want my actions to be reflected immediately in staff-facing flows without lag or mismatch.

## In Scope

- [ ] Shared order and event models across customer and staff contexts
- [ ] Staff handheld UI built on the web stack
- [ ] Table and kitchen coordination via realtime updates
- [ ] Role-specific surfaces powered by common state and events

## Out of Scope

- [ ] Full enterprise POS replacement in one phase
- [ ] Offline-native device fleet management
- [ ] Dedicated hardware procurement or provisioning systems

## Functional Requirements

### Shared State

- [ ] Guest and staff surfaces must derive from common order and table state models
- [ ] State changes must propagate across surfaces in near real time
- [ ] The system must support role-based visibility and action permissions on top of shared state

### Staff Workflows

- [ ] Staff handheld views should support order review, table status, and assistance handling
- [ ] Staff workflows should operate on the same canonical events used by guest flows
- [ ] The system should support progressive rollout of staff features without forking the data model

### Platform Layer

- [ ] New operational features should prefer reuse of the common event/state substrate
- [ ] Cross-surface consistency must be observable and debuggable

## Technical Considerations

- [ ] Reuse order events, realtime broadcasting, and projected state where available
- [ ] Define a consistent surface contract for guest and staff clients
- [ ] Ensure authorization and tenancy boundaries remain explicit for all roles
- [ ] Avoid surface-specific mutations that bypass the shared state model

## Dependencies

- [ ] Reliable order event projection
- [ ] Realtime broadcasting across guest and staff channels
- [ ] Role-aware authorization for staff and guest actions
- [ ] Shared state payload shape consumable by multiple surfaces

## Risks

- [ ] Over-unification may blur essential UX differences between staff and guests
- [ ] Realtime consistency problems would become more visible across surfaces
- [ ] Incremental rollout may expose gaps where one surface depends on assumptions from another

## Delivery Plan

### Phase 1: Shared State Foundation

- [ ] Audit current guest and staff flows for shared versus duplicated state logic
- [ ] Define a canonical surface contract for order and table state
- [ ] Remove or reduce surface-specific mutations where practical
- [ ] Validate cross-surface consistency for core ordering actions

### Phase 2: Staff Handheld Expansion

- [ ] Introduce handheld-friendly staff workflows on the shared substrate
- [ ] Add operational views for table status and order coordination
- [ ] Ensure realtime guest actions are visible in staff tools with minimal delay

### Phase 3: Platform Consolidation

- [ ] Expand the shared substrate to assistance, payment, and table coordination features
- [ ] Add instrumentation for cross-surface latency and consistency
- [ ] Define long-term patterns for future operational modules to plug into the same layer

## Acceptance Criteria

- [ ] Guest and staff surfaces can operate on the same canonical order state
- [ ] Core order changes remain consistent across surfaces
- [ ] Staff handheld workflows are viable on the existing web platform
- [ ] New surface features can be added without introducing a parallel domain model

## Success Metrics

- [ ] Reduced duplicated logic across guest and staff flows
- [ ] Lower time-to-reflect order changes across surfaces
- [ ] Higher staff adoption of handheld workflows
- [ ] Reduced coordination errors caused by mismatched state

## Open Questions

- [ ] Which staff workflows should move first onto the unified surface?
- [ ] Where does shared state end and role-specific presentation begin?
- [ ] What latency threshold is required for the shared-surface model to feel reliable in service?
- [ ] Which existing admin or restaurant management flows should stay separate from the floor operating surface?

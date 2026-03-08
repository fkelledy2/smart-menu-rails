# Table Digital Twin & State Machine Layer

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Domain Modeling, Realtime State, Restaurant Floor Platform

## Feature Overview

The table digital twin and state machine layer represents each `Tablesetting` as a live operational domain object whose projected state can drive guest UI, staff workflows, kitchen coordination, automations, and analytics.

## Problem Statement

Most ordering systems treat the table as a passive container rather than an active operational entity. This limits the ability to coordinate experiences and automations across guest, staff, kitchen, and service flows using a common source of truth.

## Goals

- [ ] Define a canonical table-level state model
- [ ] Project live table state from orders, sessions, elapsed time, and service events
- [ ] Enable UI and automation layers to respond to table context consistently
- [ ] Establish a foundational abstraction for broader restaurant-floor intelligence

## Non-Goals

- [ ] Replacing the order domain with a table-only domain model
- [ ] Modeling every restaurant workflow in the first phase
- [ ] Building opaque automations without explicit state definitions

## User Stories

- As staff, I want each table to have a clear operational state so I can prioritize service correctly.
- As a guest, I want the interface to reflect where the table is in the dining journey.
- As a product architect, I want a reusable table abstraction that other features can build on safely.

## In Scope

- [ ] Explicit table state projections
- [ ] Aggregated order and session state per table
- [ ] Table-aware UI adaptation
- [ ] Automation hooks for nudges, staffing, billing, and service timing

## Out of Scope

- [ ] Full restaurant simulation in the first release
- [ ] Fully autonomous floor orchestration without operator oversight
- [ ] Replacing role-specific staff workflows with a single generic table action model

## Functional Requirements

### Table State Model

- [ ] Each table should have a projected operational state derived from current orders, participants, service progress, and elapsed time
- [ ] The system should support explicit state transitions or computed state derivation rules
- [ ] Table state should be queryable by guest, staff, and analytics surfaces with role-appropriate visibility

### UI and Workflow Adaptation

- [ ] Guest UI should be able to adapt based on table state, spend stage, course stage, or billing stage
- [ ] Staff workflows should be able to prioritize tables based on projected state
- [ ] Automation hooks should be available for nudges, assistance, billing prompts, or service reminders

### Extensibility

- [ ] The table state model should support future layering for adaptive menus, staff routing, and table-aware experiences
- [ ] State projection should remain debuggable and recoverable from underlying events where possible

## Technical Considerations

- [ ] Reuse `Tablesetting`, order events, Smart Menu state, and projected order state where available
- [ ] Decide whether table state is explicitly event-driven, computed on demand, or hybrid
- [ ] Avoid duplicating source-of-truth order logic inside the table layer
- [ ] Ensure table projection is consistent enough for realtime UI consumers

## Dependencies

- [ ] Stable order event projection
- [ ] Reliable mapping between tables, orders, and participants
- [ ] Realtime state distribution to guest and staff surfaces
- [ ] Analytics support for table-state transitions and dwell timing

## Risks

- [ ] Over-modeling the table domain may create complexity before immediate value is proven
- [ ] Weak projection logic may produce misleading operational state
- [ ] State drift between table and order models would damage trust in the abstraction

## Delivery Plan

### Phase 1: Table State Definition

- [ ] Define the canonical table state model and primary transitions
- [ ] Map source signals from orders, participants, and time-based conditions
- [ ] Validate the model against real restaurant workflows

### Phase 2: Projection and Surface Integration

- [ ] Build table-state projection support
- [ ] Expose table state to staff and guest surfaces where appropriate
- [ ] Add instrumentation for transition accuracy and latency

### Phase 3: Automation and Platform Reuse

- [ ] Add automation hooks based on stable table states
- [ ] Use the table model as a dependency for adaptive menus, waiter routing, and service intelligence
- [ ] Document long-term extensibility patterns for future modules

## Acceptance Criteria

- [ ] Tables can be represented as live projected state objects
- [ ] The model can drive at least one guest-facing and one staff-facing behavior
- [ ] Table state can be traced back to underlying operational inputs
- [ ] The abstraction is stable enough to support downstream feature work

## Success Metrics

- [ ] Reduced ambiguity in staff table prioritization
- [ ] Faster implementation of downstream table-aware features
- [ ] Lower duplication in state logic across guest and staff surfaces
- [ ] Improved consistency in table-related automation behavior

## Open Questions

- [ ] Which table states should be explicit versus computed?
- [ ] Should course progression be represented at the table layer or only inferred from item states?
- [ ] How much table history should remain visible for analytics and debugging?
- [ ] What is the right boundary between table state and order state responsibility?

# Table Digital Twin & State Machine Layer

**Status:** Research / Strategy
**Feasibility:** Currently Feasible
**Target:** 2026+

## Vision

Represent each table as a live domain object with operational state that can drive UI, staff workflows, and automations.

## Included Ideas

- Table digital twins
- Table state machine
- UI adapts to state, spend, course count, and elapsed time

## Feasible Now

- Explicit `Tablesetting` state projections
- Aggregated order and session state per table
- Automation hooks for nudges, staffing, and billing UX

## Strategic Value

- Foundational layer for many other initiatives
- High reuse across guest, staff, kitchen, and analytics systems
- Creates a strong abstraction for restaurant-floor automation

## Suggested R&D Path

- Formalize the table state model first
- Add projections, automations, and UI adaptation on top
- Use this as the backbone for adaptive menus, waiter routing, and table-aware experiences

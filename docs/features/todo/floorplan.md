# Floorplan Dashboard (Abstract Table Map)

## 📋 Feature Overview

**Feature Name**: Floorplan Dashboard
**Priority**: High
**Category**: Restaurant Operations
**Primary Users**: Restaurant managers + staff

Provide an **abstract** (not-to-scale) or optionally **scaled** floorplan view of the restaurant where each table is shown as a stylised tile/card/infographic.

This is intended to be a fast “single-glance” operational view of:
- table occupancy and capacity
- active order status per table
- bill requested / payment state indicators

## 🎯 User Story

**As a** restaurant manager or staff member
**I want to** see an at-a-glance floorplan showing each table and its current status
**So that** I can coordinate service, proactively identify delays, and respond quickly to tables needing attention.

## ✅ Requirements

### 1) Floorplan view
- Display a grid/map of tables for a restaurant.
- Each table is represented as a stylised tile with clear status colours and icons.
- Support both:
  - **Auto layout** (default): smart grid layout by table number/name
  - **Custom layout** (later): drag and drop to arrange tables

### 2) Table tile attributes (must display)
Each table tile shows:
- **Table name** (e.g. “T1”, “Patio 3”, “Bar 2”)
- **Table capacity**
- **Table status** (see “Status model” below)
- **When the active order started** (or seated time if tracked)
- **Participant count** (how many people are part of the order; not necessarily equal to capacity)
- **Order status visualization** (e.g. opened/ordered/preparing/ready/delivered)
- **Bill requested visualization**
- **Payment status visualization (paid/unpaid)**

### 3) Filtering / UX
- Ability to filter to:
  - **Only active tables** (occupied)
  - **Tables with bill requested**
  - **Tables delayed** (order started > X minutes)
- Optional: search by table name.

### 4) Real-time updates
- When any relevant state changes, the tile updates without full page reload.

## Status model (proposed)

### Table status
A table tile has a “table status” that is derived from data:
- **Available**: no open order
- **Occupied**: has open order
- **Attention**: heuristic status (e.g. bill requested OR stuck in preparing/ready too long)

### Order status
Reuse the existing `Ordr.status` state machine:
- `opened`
- `ordered`
- `preparing`
- `ready`
- `delivered`
- `billrequested`
- `paid`
- `closed`

Payment state should be visualized as **paid/unpaid**, derived from:
- `Ordr.status` (paid/closed => paid)
- and/or `Ordr.paymentstatus` (if present and authoritative)

For the floorplan we likely treat only one “active” order per table:
- Active = `opened`, `ordered`, `preparing`, `ready`, `delivered`, `billrequested`
- Inactive = `paid`, `closed`

## Data model & queries

### Inputs
For a given `restaurant_id`, the floorplan needs:
- Tables: `Tablesetting` (or the canonical table model in this app)
  - name/label
  - capacity
- Active orders for those tables: `Ordr` scoped to restaurant
  - status
  - created_at (start time)
  - tablesetting_id
- Participant count per order: `ordrparticipants.count`
- Optional: derived “has food ordered / delivered”
  - if using station tickets, aggregate `ordr_station_tickets` per order
  - else infer from `ordritems.status` distribution

### Suggested query shape
- Load all tables for restaurant
- Load active orders for those tables in one query
- Load counts (participants) via counter cache or grouped query

### Performance / caching
- Keep the floorplan endpoint fast (single response) and push updates via ActionCable.
- Consider adding:
  - `ordrs.participants_count` counter cache (if needed)
  - `tablesettings.current_ordr_id` denormalization (optional)

## UI / Visualization

### Table tile design
A single table tile should include:
- Header: table name + capacity badge
- Body: “Since: HH:MM” or “10m ago”
- Footer: participant count + status chips

### Status chips (examples)
- Order status chip: color-coded
  - opened: gray
  - ordered: blue
  - preparing: orange
  - ready: green
  - delivered: muted green
  - billrequested: purple
- Bill requested icon/badge: visible when `ordr.status == billrequested`

- Payment status badge:
  - unpaid: show when active order exists and not paid
  - paid: show when `ordr.status` is `paid` or `closed` (and/or `paymentstatus` indicates paid)

### Attention heuristics (optional)
- “Delayed” indicator if:
  - `preparing` for > N minutes
  - `ready` for > N minutes
  - `billrequested` for > N minutes

## Permissions
- Restaurant **manager**: full access
- Restaurant **staff**: read access (and possibly limited actions)
- Enforce restaurant ownership/employee membership in controller.

## Actions (optional, phase 2)
From a table tile:
- open table/order details
- mark ready / mark delivered / request bill (role-gated)

## Real-time architecture

### Recommendation
Reuse existing ActionCable infrastructure.

Potential options:
- Broadcast on an existing restaurant-scoped channel (if one exists)
- Or create a new `FloorplanChannel` with a stream name like:
  - `"floorplan:restaurant:#{restaurant.id}"`

Events to broadcast:
- order created/assigned to table
- order status updated
- participants added/removed
- bill requested / paid

Client behavior:
- subscribe on page load
- update the specific table tile based on `tablesetting_id`

## Implementation Plan
1. Create a floorplan page route under restaurant operations (manager/staff).
2. Build server endpoint returning initial floorplan payload.
3. Build UI grid of table tiles.
4. Wire ActionCable subscription + incremental updates.
5. Add heuristics + filters.
6. Add custom layout (drag/drop) if required.

## Open Questions
1. What is the canonical “table” model for this feature (`Tablesetting` vs another model)?
2. Can there be multiple active orders per table? If yes, what is the display rule?
3. Should we show separate Kitchen/Bar progress on the tile (using station tickets)?
4. Should staff be able to perform actions from the tile, or view-only initially?

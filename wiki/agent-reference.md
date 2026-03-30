# Smart Menu — Agent Reference

This document contains extended reference material.

Only read when required.

---

## Directory Overview

Controllers
app/controllers

Services
app/services

Jobs
app/jobs

Stimulus controllers
app/javascript/controllers

Shared modules
app/javascript/modules

Customer Smartmenu views
app/views/smartmenus

Restaurant admin views
app/views/restaurants

Policies
app/policies

---

## Smartmenu View Structure

Main page
app/views/smartmenus/show.html.erb

Shared modals
_showModals.erb

Customer menu sections
_menu_section.html.erb

Customer menu item cards
_showMenuitem.erb

Horizontal layout
_showMenuitemHorizontal.html.erb

Staff menu rows
_showMenuitemStaff.erb

Cart bottom sheet
_cart_bottom_sheet.html.erb

---

## Stimulus Controllers

Core state manager
state_controller.js

Order totals
order_totals_controller.js

Bottom sheet UI
bottom_sheet_controller.js

Staff quick add
quick_add_controller.js

Ordering lifecycle
ordering_controller.js

Square payments
square_payment_controller.js

---

## Database Notes

Schema file
db/schema.rb

Total tables ≈ 105

Key tables:

ordrs
ordritems
ordractions
ordrparticipants
menus
menusections
menuitems
tablesettings
restaurants
users
employees

Materialized views:
dw_orders_mv

Important invariant:
Each ordritem represents one unit (no quantity column currently).

---

## Feature Specs

Active specs
docs/features/todo/2026/

Completed
docs/features/done/

In progress
docs/features/in-progress/

---

## Route Structure

Most resources nested under:

resources :restaurants

Examples:

restaurants → menus → menusections → menuitems
restaurants → ordrs
restaurants → tablesettings
restaurants → employees
restaurants → inventories

Customer menu access:
resources :smartmenus

API endpoints:
namespace :api
namespace :v1
namespace :v2

---

## Docs Generation

Reference docs can be regenerated with:

bin/generate_docs

Generated files:

docs/ARCHITECTURE.md
docs/DATA_MODEL.md
docs/SERVICE_MAP.md


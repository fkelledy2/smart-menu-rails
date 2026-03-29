---
name: User Guide Inventory — March 2026
description: Which completed feature docs have user guides, which are internal-only, and known gaps
type: project
---

As of 2026-03-29, the following guides exist in `/docs/user_guides/`:

| Guide file | Feature doc | Status |
|---|---|---|
| jwt-token-management.md | mellow-admin-jwt-token-management-feature-request.md | Pre-existing, comprehensive |
| qr-code-security.md | qr-security.md | Written 2026-03-29 |
| auto-pay-and-leave.md | auto-pay-and-leave-combined.md | Written 2026-03-29 |
| branded-receipt-emails.md | branded-receipt-email-feature-request.md | Written 2026-03-29 |
| branded-system-emails.md | branded-email-styling-feature-request.md | Written 2026-03-29 |
| floorplan-dashboard.md | floorplan.md | Written 2026-03-29 |
| employee-order-notes.md | EMPLOYEE_ORDER_NOTES_IMPLEMENTATION.md + employee-order-notes-feature-request.md | Written 2026-03-29 |
| menu-item-profit-margins.md | menu-item-profit-margin-tracking-COMPLETE.md | Written 2026-03-29 — source doc had significant text corruption in Phases 2–4 |
| smartmenu-theming.md | smartmenu-theming.md | Written 2026-03-29 |
| pre-configured-marketing-qr-codes.md | pre-config-qrs.md | Written 2026-03-29 |
| crm-sales-funnel.md | crm-sales-funnel.md | Written 2026-03-29 |
| partner-integrations.md | 06-partner-integrations-event-driven.md | Written 2026-03-29 |
| demo-booking.md | homepage-demo-booking-feature-request.md | Written 2026-03-29 |
| menu-ab-experiments.md | 08-menu-experiments-ab-testing.md + 08-menu-experiments-ab-testing-README.md | Written 2026-03-29 — README in completed/ is a technical internal guide, not the user guide |

Features with NO user-facing guide (internal/infrastructure only):
- `pentest_remediation.md` — security engineering fixes, no user-facing workflow
- `security_upgrade.md` — gem upgrades and security hardening, no user-facing workflow

**Why:** These are internal platform hardening tasks. There is nothing a restaurant owner or customer needs to do differently as a result.

**How to apply:** If asked to write guides for all completed features, skip these two. If asked specifically about security improvements, refer to the platform's security disclosure page or support team.

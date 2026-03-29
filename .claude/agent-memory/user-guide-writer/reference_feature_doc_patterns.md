---
name: Recurring Patterns in Completed Feature Requirement Docs
description: Patterns and anti-patterns found in /docs/features/completed docs that affect how user guides should be written
type: reference
---

## Document quality varies significantly
- Implementation summary docs (e.g., EMPLOYEE_ORDER_NOTES_IMPLEMENTATION.md) are more reliable than feature request docs because they describe what was actually built
- Some docs have heavy text corruption (repeated characters, truncated lines) — seen in menu-item-profit-margin-tracking-COMPLETE.md; work around by checking the actual implementation files
- Feature request docs sometimes describe aspirational features not yet built — always cross-check with the codebase (model files, services, controllers)

## Two-document pattern for some features
- Some features have both a feature request doc AND an implementation summary doc
- The implementation doc is ground truth; the request doc provides context on the "why"
- Employee order notes is the main example: two files exist in completed/

## Flipper flags are always per-restaurant unless otherwise noted
- Default: flags are off; restaurants opt in via admin/support
- Admin-only features (CRM, marketing QRs) use email domain gating (`@mellow.menu`) instead of Flipper
- Some features note "Pro plan and above" as a prerequisite — check the requirement for plan gating

## Open Questions in requirement docs
- Many specs have open questions that were never formally resolved
- When writing guides, use the most conservative/safe assumption
- Flag with `<!-- TODO: clarify ... -->` when the ambiguity could cause user confusion

## README-style guides already in completed/
- `08-menu-experiments-ab-testing-README.md` is essentially a user guide already, but written in a different format and kept in the features/ tree
- A proper user-guide-format version was written to user_guides/menu-ab-experiments.md

## Internal-only features that need no user guide
- pentest_remediation.md — pure security engineering
- security_upgrade.md — pure gem/infrastructure upgrade
- Neither has any user-visible workflow changes

## Features with multi-persona workflows
- Auto Pay & Leave: customer adds card + enables auto-pay; staff monitors and overrides
- Employee Order Notes: staff creates notes; kitchen staff reads them; customers see customer-visible subset
- Partner Integrations: mellow admin provisions; partner engineers call APIs; restaurant owners may want to understand what is shared
- Receipt Emails: staff sends; customer self-requests
- These should use sub-sections per persona in the guide

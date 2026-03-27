---
name: CRM is admin-namespace only
description: CRM Sales Funnel lives in admin/ namespace with no restaurant-tenant scoping — platform-level data only
type: project
---

The CRM Sales Funnel feature (spec: `docs/features/todo/backlog/crm-sales-funnel.md`) is entirely admin-only. All four CRM models (`CrmLead`, `CrmLeadNote`, `CrmLeadAudit`, `CrmEmailSend`) are unscoped from the multi-tenant `Restaurant` pattern. No `restaurant_id` tenant scope is applied to queries — these models belong to mellow.menu the business, not to any restaurant customer.

**Why:** Sales pipeline data is internal company data. Restaurant owners and customers must never access it. Pundit policies enforce admin-only access on all CRM actions.

**How to apply:** When referencing or extending CRM models in future specs, do not suggest tenant-scoping. All CRM controllers live under `app/controllers/admin/crm/`.

# Partner Integrations — User Guide

## Overview

Partner Integrations gives third-party software platforms — such as workforce scheduling tools and customer relationship management (CRM) systems — secure, read-only access to mellow.menu operational data via a structured API. Workforce tools can pull order velocity and table occupancy data to plan staffing. CRM platforms can pull guest behaviour signals to enrich customer profiles. All access is authenticated with JWT tokens and scoped to specific data sets.

## Who This Is For

- **mellow.menu admins** who provision and manage integration access for restaurants.
- **Technical teams at partner organisations** who build and maintain integrations against the mellow.menu API.
- **Restaurant owners and managers** who want to understand what data is shared with their connected tools.

## Prerequisites

- The `partner_integrations` Flipper feature flag must be enabled for the restaurant. Contact mellow.menu support.
- A JWT API token with the appropriate scope must be issued for the restaurant. See the [JWT Token Management guide](/docs/user_guides/jwt-token-management.md).
- For workforce data access, the token must have the `workforce:read` scope.
- For CRM data access, the token must have the `crm:read` scope.

## How To Use

### For mellow.menu Admins — Enabling Integrations

1. Sign in to the admin panel.
2. Go to **API Tokens** and issue a token for the relevant restaurant with the required scope (`workforce:read`, `crm:read`, or both).
3. Enable the `partner_integrations` flag for the restaurant in the Flipper UI.
4. Deliver the token securely to the partner's technical team (email delivery or one-time download — see the JWT Token Management guide).

To enable specific adapter types for a restaurant (for example, connecting a workforce tool):

Contact mellow.menu support to enable specific integration adapters for a restaurant. Integration adapter configuration is managed by mellow.menu staff and is not available as a self-serve setting in v1.

### For Partner Technical Teams — Accessing the API

**Workforce data endpoint**

```
GET /api/v1/restaurants/{restaurant_id}/partner/workforce
Authorization: Bearer {your_jwt_token}
```

Returns:
- Order velocity (orders per minute over recent periods)
- Average item preparation times (from order placed to order ready)
- Table occupancy durations

**CRM signals endpoint**

```
GET /api/v1/restaurants/{restaurant_id}/partner/crm
Authorization: Bearer {your_jwt_token}
```

Returns:
- In-meal order pacing (how quickly customers order over the course of a sitting)
- Time from first item added to bill requested
- Table session duration

Both endpoints return JSON. A token with the wrong scope returns a `403 Forbidden` response. An expired or revoked token returns `401 Unauthorized`.

### For Restaurant Owners — Understanding What Is Shared

When partner integrations are active for your restaurant, the following data types may be accessible to connected partners, depending on the scopes granted to their token:

| Data type | Scope required | What it includes |
|---|---|---|
| Order velocity | `workforce:read` | Aggregate counts — orders per time period |
| Prep times | `workforce:read` | Average kitchen preparation durations |
| Table occupancy | `workforce:read` | How long tables are occupied, in aggregate |
| Order pacing | `crm:read` | How quickly customers place orders during a sitting |
| Time to bill | `crm:read` | Duration from ordering to requesting the bill |
| Session duration | `crm:read` | Length of dining sessions |

No individual customer personal data (names, emails, payment details) is shared via partner integration endpoints.

## Key Concepts

**Partner event** — a standardised signal generated when something significant happens in mellow.menu (an order is created, a payment succeeds, a table is freed). These events are delivered to connected adapters automatically.

**Adapter** — the component that receives partner events and forwards them to a specific third-party system. Each integration type has its own adapter. Adapters are independent — removing one does not affect any other integration.

**Dead-letter log** — if an adapter fails to deliver an event after retrying, the failure is recorded in a dead-letter log for investigation. The failure does not affect order processing or any other part of the platform.

**Canonical event** — the standardised event format that mellow.menu uses internally. Partners receive data in this format regardless of which internal systems generated it.

**Workforce signals** — aggregate data about order flow and kitchen throughput, useful for staffing optimisation.

**CRM signals** — aggregate data about guest dining patterns, useful for personalisation and loyalty programmes.

## Tips & Best Practices

- Grant only the minimum scopes needed for each integration. A workforce tool does not need `crm:read`.
- Monitor the dead-letter log periodically to catch failing adapter dispatches early. Contact mellow.menu support if you see recurring failures.
- Set realistic token expiry dates for long-running integrations and plan for renewal before the token expires (the system sends a 7-day expiry warning email).
- Partner data is computed from live and recent historical data — it is most useful for near-real-time operational applications like staffing, not for long-term trend analysis.

## Limitations & Known Constraints

- v1 is pull-only. Partners query the API when they need data — there is no push notification to partner webhooks when events occur. Event push is a future feature.
- Two-way sync (partners writing data back to mellow.menu) is not supported.
- There is no self-serve partner management UI inside mellow.menu for restaurant owners. Integration configuration is handled by mellow.menu staff.
- Twilio and messaging provider integrations are not included in v1.
- Adapter metrics (success and failure counts per adapter) are managed by mellow.menu support staff. Restaurant owners do not have a self-serve view of this data in v1.

## Frequently Asked Questions

**Q: How do I know if an integration is actively receiving data?**
A: Contact mellow.menu support to check the success/failure metrics for your restaurant's active adapters.

**Q: What happens if the partner system is unavailable when an event fires?**
A: The dispatch is retried automatically up to three times with increasing delays. If all retries fail, the failure is logged in the dead-letter log for investigation. Order processing is not affected.

**Q: Can a partner access data from restaurants other than the one their token was issued for?**
A: No. JWT tokens are scoped to a single restaurant. A token for Restaurant A cannot access data for Restaurant B, even if the caller knows the correct endpoint.

**Q: Is customer personal data included in the partner API responses?**
A: No. Workforce and CRM endpoints return aggregate operational signals only. Individual customer names, emails, and payment details are never included.

**Q: What do I do if our token is compromised?**
A: Contact mellow.menu support immediately to revoke the token. Revocation is instant. A new token can be issued once the situation is resolved.

# JWT Token Management — User Guide

**Audience:** mellow.menu staff (super admin)
**Access:** Admin panel → API Tokens

---

## Overview

JWT Token Management lets mellow.menu staff issue API credentials to restaurant partners and integration developers. Each token is scoped to a specific restaurant, carries a defined set of permissions, and is rate-limited. Tokens are the only supported method for third-party API access.

---

## Who Can Use This

Access is restricted to mellow.menu staff accounts — your email must end in `@mellow.menu`. Restaurant owners and employees cannot access this section.

---

## Navigating to API Tokens

1. Sign in to the admin panel
2. Open the **Admin** dropdown in the top navigation bar
3. Click **API Tokens**

You will see a table listing all tokens across all restaurants, with their status, scopes, expiry date, and usage count.

---

## Creating a Token

1. Click **New API Token** (top right of the token list)
2. Complete the form:

| Field | Description |
|---|---|
| **Restaurant** | The restaurant this token grants access to. Required. |
| **Token name** | A human-readable label — e.g. `POS Integration (Square)`. Shown in logs. |
| **Description** | Optional. Internal notes about what the token is used for. |
| **Expiry** | Choose 30, 60, or 90 days from today. Tokens cannot be created without an expiry. |
| **Scopes** | The permissions this token grants. See [Scopes](#scopes) below. |
| **Rate limit (per minute)** | Maximum API requests per minute. Default: 60. Range: 1–1,000. |
| **Rate limit (per hour)** | Maximum API requests per hour. Default: 1,000. Range: 1–10,000. |

3. Click **Create Token**

### ⚠ One-time display

After creation you will be taken to the token detail page. **The raw JWT is shown exactly once** in a highlighted box at the top of the page. It is never stored and cannot be retrieved again. Copy it, email it, or download it before navigating away.

---

## Delivering a Token to the Recipient

From the token detail page you have two delivery options:

### Email delivery
1. Enter the recipient's email address in the **Send token by email** form
2. Click **Send** — the raw JWT is emailed with the token's scopes and expiry details

### Download as file
Click **Download .txt** to save the raw JWT as a text file you can share securely via another channel.

---

## Scopes

Each token is issued with one or more scopes that define what the API caller can do. Grant only the scopes the integration actually needs.

| Scope | What it allows |
|---|---|
| `menu:read` | Read menu sections, items, and prices |
| `menu:write` | Create and update menu items |
| `orders:read` | Read orders and order items |
| `orders:write` | Create orders and add items |
| `analytics:read` | Read sales and performance dashboards |
| `settings:read` | Read restaurant settings |

---

## Token Statuses

| Status | Meaning |
|---|---|
| **Active** | Token is valid and can authenticate API requests |
| **Expired** | Past its expiry date — API calls will be rejected |
| **Revoked** | Manually cancelled — API calls will be rejected immediately |

---

## Revoking a Token

Revocation is **immediate and permanent** — the token cannot be reinstated.

1. Open the token detail page (click the token name in the list)
2. Click **Revoke token** and confirm
3. The token status changes to **Revoked** and its revocation timestamp is recorded

Revoke a token if: a recipient's access should end early, credentials have been compromised, or a project has concluded.

---

## Viewing Usage Logs

The token detail page shows the **20 most recent API calls** made with that token:

| Column | Description |
|---|---|
| Time | UTC timestamp of the request |
| Method | HTTP method (GET, POST, PATCH, DELETE) |
| Endpoint | API path called |
| Status | HTTP response status code |
| IP | Originating IP address |

Usage logs are retained for **90 days** and then purged automatically.

---

## Rate Limiting

Each token enforces two independent rate limits:

- **Per-minute limit** — protects against burst abuse
- **Per-hour limit** — caps sustained throughput

When a limit is exceeded the API returns `429 Too Many Requests`. The rate limits are set at creation time and cannot be edited — revoke and reissue the token if limits need to change.

---

## Expiry Notifications

The token holder receives an email **7 days before expiry** reminding them to request a new token. Notifications are sent automatically by a background job — no manual action is required.

---

## Feature Flag

JWT API access is controlled by the **`jwt_api_access`** Flipper feature flag. While the flag is disabled (the default), the token infrastructure is in place but no API requests can authenticate via JWT. Enable the flag via the Flipper UI once the first token has been issued and tested end-to-end.

---

## Security Notes

- Raw JWTs are **never stored** in the database. Only a SHA-256 hash is persisted for validation.
- Tokens are signed with HS256 using the application's secret key.
- All token management actions are restricted to `@mellow.menu` accounts — Pundit policies enforce this server-side regardless of any URL manipulation.
- Tokens are **restaurant-scoped** — a token for Restaurant A cannot access Restaurant B's data even if the caller guesses the right endpoint.

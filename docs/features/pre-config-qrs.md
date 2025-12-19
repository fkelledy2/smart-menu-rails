# Pre-Configured Marketing QR Codes (Branded, Printable)

## 📋 **Feature Overview**

**Feature Name**: Pre-Configured Marketing QR Codes (Holding Redirect + Later Linking)
**Priority**: High
**Category**: Growth / Marketing / QR Codes
**Estimated Effort**: Medium-Large (3-6 weeks)
**Target Release**: TBD

## 🎯 **User Story**

**As a** mellow.menu admin user (someone who has an `@mellow.menu` email address)
**I want to** generate branded, printable marketing QR codes in advance
**So that** we can distribute physical marketing materials before a menu (or table setup) is finalized

**As a** mellow.menu admin user
**I want to** later link those pre-generated marketing QR codes to a specific menu or table
**So that** the marketing material becomes “live” without requiring reprinting

## 📌 **Problem Statement & Goals**

Today, the QR code system is tightly coupled to `/smartmenus/:slug`, where the QR encodes a Smartmenu `slug` that maps to a (restaurant_id, menu_id, tablesetting_id) context.

For marketing, we need the ability to:

- Generate QR codes *before* the menu/table context is known.
- Have those QR codes safely route to a holding experience until linked.
- Later “activate” them by linking to a specific Menu or Table.

**Key goal**: decouple QR generation from menu deployment while remaining compatible with the current Smartmenu-based QR system.

## ✅ **Detailed Requirements**

### **Primary Requirements**

#### **1. Generate branded, printable marketing QR codes**
- Generate a QR code asset intended for print (e.g., A5/A6 flyer, table-tent, window sticker).
- QR code should encode a stable URL that **initially redirects to a holding URL**.
- QR code styling should be branded (logo, colors) consistent with existing menu QR styling (`QRCodeStyling` usage).

#### **2. Later link marketing QR codes to a menu or a table**
- An admin should be able to select:
  - a `Restaurant`
  - either:
    - a `Menu` (menu-level / all tables)
    - or a specific `Tablesetting` (table-specific)
- After linking, scanning the marketing QR should route to the correct end destination.

#### **3. Decouple printing from deployment**
- QR codes can be printed and distributed immediately.
- Activation can happen later without regenerating the QR code.

#### **4. Compatibility with existing `/smartmenus` logic**
- Existing QR codes that encode `/smartmenus/:slug` must remain unchanged.
- The new marketing QR codes should integrate by ultimately routing **into** the Smartmenu flow whenever possible.
- We should avoid duplicating menu rendering logic; `/smartmenus` should remain the canonical public menu rendering endpoint.

#### **5. Admin-only access restriction**
- Only users with email addresses ending in `@mellow.menu` can:
  - create/generate marketing QR codes
  - link/unlink marketing QR codes
  - download/print marketing QR codes

### **Secondary Requirements (Nice-to-have / Later)**

- **Audit trail** of QR creation, linking, unlinking, prints/downloads.
- **Bulk generation** (e.g., generate 100 codes for a campaign).
- **Campaign metadata** (name, channel, venue, partner).
- **Analytics** (scan counts, unique devices, last scanned time, geo breakdown).

## 🧩 Proposed Solution (High-Level Design)

### Core Idea
Introduce a new first-class entity: **MarketingQrCode**.

- Marketing QR is **not** a Smartmenu.
- Marketing QR has its own immutable token/slug.
- When scanned it hits a new public endpoint, e.g.:

`GET /m/:token`

That endpoint will:

- If not yet linked: redirect to a holding URL (or render a holding page).
- If linked: redirect to the correct destination:
  - ideally `/smartmenus/:slug`
  - or to a stable menu/table redirect endpoint that ultimately resolves to a Smartmenu

### Why not just create Smartmenus up front?
Smartmenus are per (restaurant, menu, table). Marketing QR codes are **pre-context**, so we need a layer that can be later linked.

## 🔧 Technical Specifications

### **1) Data model**

Create a new model/table:

- `marketing_qr_codes`
  - `id`
  - `token` (string, unique, immutable; e.g., SecureRandom.uuid)
  - `status` (enum: `unlinked`, `linked`, `archived`)
  - `holding_url` (string, optional; default system holding page)
  - Linkable target (polymorphic or explicit foreign keys)
    - Option A (explicit): `restaurant_id`, `menu_id` nullable, `tablesetting_id` nullable
    - Option B (polymorphic): `target_type`, `target_id` (Menu or Tablesetting)
  - `smartmenu_id` nullable (optional cached resolution)
  - `name` / `campaign` metadata
  - `created_by_user_id` (admin user)
  - `created_at`, `updated_at`

**Recommendation**: Use explicit `restaurant_id`, `menu_id`, `tablesetting_id` to align with Smartmenu’s structure and simplify resolution.

### **2) Routing / Redirect behavior**

Add a public endpoint:

- `GET /m/:token` → `MarketingQrCodesController#resolve`

Resolution rules:

- If `status=unlinked`:
  - Redirect to `holding_url` if present
  - Else render a default holding page (e.g., “Menu coming soon”)

- If `status=linked`:
  - Resolve to a Smartmenu slug based on linking fields:
    - if linked to menu only: find/create Smartmenu for `(restaurant_id, menu_id, tablesetting_id=nil)`
    - if linked to table: find/create Smartmenu for `(restaurant_id, menu_id, tablesetting_id=table_id)`
  - Redirect to `/smartmenus/:slug`

Important: This preserves `/smartmenus` as the rendering surface.

### **3) Admin UI**

Add an admin-only UI (could live under an existing admin area or a new namespace):

- `GET /admin/marketing_qr_codes`
- `POST /admin/marketing_qr_codes` (generate)
- `PATCH /admin/marketing_qr_codes/:id/link`
- `PATCH /admin/marketing_qr_codes/:id/unlink`
- `GET /admin/marketing_qr_codes/:id/print` (renders a printable view)

### **4) QR code generation**

We should reuse the existing JS-based approach used in the menu QR section:

- `QRCodeStyling`
- same logo asset and styling parameters

But the encoded URL becomes:

- `https://<host>/m/<token>`

Print layout can reuse the existing “qr-card” style and `printQrCard()` helper pattern.

### **5) Authorization / Admin-only**

Implement a simple helper:

- `current_user.email.ends_with?('@mellow.menu')`

Enforce via:

- controller `before_action :require_mellow_admin!`
- optional Pundit policy (recommended if you want consistent authorization patterns)

This is consistent with other feature requests that identify mellow admins by email domain.

## 🔁 Compatibility with existing Smartmenus / QR Flow

- Existing menu/table QR codes remain:
  - encoded as `https://<host>/smartmenus/:slug`
- Marketing QR codes are new:
  - encoded as `https://<host>/m/:token`
  - but when linked they redirect into `/smartmenus/:slug`

This preserves:

- the Smartmenu state model and caching behavior
- the public rendering logic
- table/order context logic

## 🗺️ Implementation Plan

### **Phase 0: Discovery / Alignment (1-2 days)**
- Confirm expected “holding experience”:
  - redirect to marketing site?
  - or render a mellow “coming soon” page?
- Confirm whether linking should allow:
  - menu-only
  - table-only
  - menu+table (recommended)

### **Phase 1: Backend foundation (3-5 days)**
- Add `MarketingQrCode` model + migration
- Add `MarketingQrCodesController#resolve` (public endpoint)
- Implement Smartmenu resolution logic:
  - reuse or call existing Smartmenu generation (SmartMenuGeneratorJob patterns)
  - ensure idempotent find-or-create

### **Phase 2: Admin-only management UI (5-10 days)**
- Admin controller + views
- List view with statuses
- Create/generate flow
- Link/unlink flow with restaurant/menu/table selectors
- Print view (HTML optimized for printing)

### **Phase 3: QR rendering + printing (3-5 days)**
- Reuse existing QR card components + `QRCodeStyling`
- Ensure correct encoded URL
- Provide download (PNG/SVG) if needed

### **Phase 4: Hardening (3-5 days)**
- Add audit logging
- Add validations (linked must have restaurant + target)
- Add basic rate limiting / abuse prevention on `/m/:token` if needed

## 🧪 Testing Plan

- Model tests:
  - token uniqueness
  - linking validations
- Request specs:
  - `/m/:token` unlinked → holding
  - `/m/:token` linked → redirects to `/smartmenus/:slug`
  - idempotent Smartmenu creation
- Authorization tests:
  - non-`@mellow.menu` users cannot access admin endpoints

## 🚧 Risks / Considerations

- **Scanning domain**: If you plan to print QR codes for production, ensure the encoded host is stable (e.g., `mellow.menu`), not an environment-specific host.
- **Slug stability**: Marketing token is immutable. Smartmenu slug can be created at link time.
- **Table/menu existence**: linking UI should validate that referenced menu/table exists and belongs to the restaurant.
- **Analytics**: If scan tracking is required, we should log at the `/m/:token` endpoint.

## ✅ Success Criteria

- Admin can generate marketing QR codes before a menu/table exists.
- Scanning before linking sends the user to a holding experience.
- Admin can later link the code to a menu or table.
- After linking, scanning redirects into `/smartmenus/:slug`.
- Only `@mellow.menu` users can generate/link/manage these codes.

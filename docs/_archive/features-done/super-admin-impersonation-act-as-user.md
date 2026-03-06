# Super Admin “Act as User” (Impersonation) Feature Request

## 📋 **Feature Overview**

**Feature Name**: Super Admin “Act as User” (Impersonation)
**Priority**: High
**Category**: Admin / Support Operations / Security
**Estimated Effort**: Medium (3-5 days)
**Target Release**: Q1 2026

## 🎯 **User Story**

**As a** super admin (mellow.menu support)
**I want to** act as any user on the site
**So that** I can reproduce issues, validate UX, and support customers without requiring customer screen-sharing.

**As a** customer
**I want** support to diagnose issues accurately
**So that** problems are resolved faster with fewer back-and-forth messages.

## ✅ **Current State (Already Implemented Partially)**

The application already includes:

- `pretender` gem (`Gemfile`: `pretender ~> 0.3.4`)
- Admin routes under `authenticate :user, lambda { |u| u.admin? }`:
  - `POST /madmin/impersonates/:id/impersonate`
  - `POST /madmin/impersonates/stop_impersonating`
- Controller: `app/controllers/madmin/impersonates_controller.rb`
  - Uses `impersonates :user`, `impersonate_user(user)`, `stop_impersonating_user`

This feature formalizes the behavior as a **production-ready Super Admin impersonation system**, adds **role separation**, **UI/UX**, **DB audit logging**, **session-only expiry**, and **risk controls**.

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Super Admin Role (`User#super_admin?`)**
- [ ] Add a new `User#super_admin?` authorization predicate.
- [ ] Initial super admin account: `admin@mellow.menu`.
- [ ] System must support adding more super admins later (e.g., by DB flag).

**Decision**: Super admin is a distinct permission from `admin?`.

#### **2. “Act as” Entry Point (Search Bar)**
- [ ] In the admin surface, provide a search input (“Act as user”) accepting:
  - User email
  - User id
- [ ] When a user is found, display a confirmation UI:
  - User name/email
  - Restaurants owned (if applicable)
  - “Start impersonation” CTA

**Non-goals**:
- Not required to add a full CRM-style user explorer.

#### **3. Persistent Banner While Impersonating**
- [ ] Show a persistent banner on all pages when impersonating:
  - `Acting as <email> (Stop)`
- [ ] Banner must be visible across both HTML pages and Turbo navigations.
- [ ] Banner must provide a clear “Stop” action.

#### **4. Session-Only + Auto-Expire After 30 Minutes**
- [ ] Impersonation must be session-only.
- [ ] Impersonation must automatically stop after 30 minutes.
- [ ] After expiry:
  - The admin is returned to their own session.
  - A flash message indicates impersonation expired.

#### **5. Audit Logging Persisted to DB**
- [ ] Every impersonation session must create an audit record.
- [ ] Audit record must include:
  - `admin_user_id`
  - `impersonated_user_id`
  - `started_at`, `ended_at`
  - `expires_at`
  - `ip_address`
  - `user_agent`
  - `reason` (optional, but supported)
  - `ended_reason` (e.g. `manual_stop`, `expired`, `forced_stop`)

#### **6. Risk Controls: Block High-Risk Actions By Default**
- [ ] While impersonating, block “high-risk actions” unless explicitly enabled.

**Default blocked categories** (recommended):
- Billing/Payments:
  - Stripe portal / plan changes / refunds
- Account takeover:
  - change email/password
  - connect/disconnect OAuth providers
- Destructive admin operations:
  - deleting restaurants
  - deleting menus

**Allow-by-default**:
- Most “debuggable UX paths” (read flows, CRUD that helps reproduction), subject to existing Pundit authorization.

**Implementation note**: this is a policy layer on top of existing authorization.

### **Secondary Requirements**

#### **7. Admin Observability**
- [ ] Log structured events on start/stop/expire:
  - `impersonation.started`
  - `impersonation.stopped`
  - `impersonation.expired`
- [ ] Provide a basic admin view to list impersonation audits (optional for v1; acceptable as a follow-up).

#### **8. Safety UX**
- [ ] Banner should use a distinct visual style to avoid confusion.
- [ ] Optional (recommended): show a “reason” text area when starting impersonation.

## 🔧 **Technical Specifications**

### **Rails Gems / Existing Support**

#### **Chosen approach**: Build on `pretender`
- Already present and wired into `Madmin::ImpersonatesController`.
- Provides:
  - `impersonate_user(user)`
  - `stop_impersonating_user`
  - tracking original user in session

#### **Alternatives (not recommended for this codebase right now)**
- `devise_masquerade`:
  - works well for Devise apps
  - but would require migration from an already-working `pretender` setup

### **Backend Implementation Plan**

#### **A. Data Model: `ImpersonationAudit`**

Create a new model and table.

**Schema (conceptual):**

```ruby
# db/migrate/...create_impersonation_audits.rb
create_table :impersonation_audits do |t|
  t.references :admin_user, null: false, foreign_key: { to_table: :users }
  t.references :impersonated_user, null: false, foreign_key: { to_table: :users }

  t.datetime :started_at, null: false
  t.datetime :ended_at
  t.datetime :expires_at, null: false

  t.string :ip_address
  t.string :user_agent

  t.string :ended_reason
  t.text :reason

  t.timestamps
end

add_index :impersonation_audits, :expires_at
add_index :impersonation_audits, [:admin_user_id, :started_at]
add_index :impersonation_audits, [:impersonated_user_id, :started_at]
```

**Model behavior (high-level):**
- On impersonation start: create audit row with `started_at` and `expires_at = 30.minutes.from_now`.
- On stop: set `ended_at` and `ended_reason`.

#### **B. Authorization Layer**

- Update access control for impersonation routes:
  - `admin?` is not sufficient
  - require `super_admin?`

**Preferred enforcement points**:
- Route constraint stays `admin?` for madmin access, but impersonation endpoints add a stricter guard:
  - `before_action :require_super_admin!`

#### **C. Controller Updates**

**Existing controller**: `Madmin::ImpersonatesController`.

Enhancements:
- Start impersonation:
  - validate `current_user.super_admin?`
  - find user by id (existing) and (new) by email
  - record audit row
  - store `impersonation_audit_id` in session
- Stop impersonation:
  - update audit row
  - clear session

**New endpoints** (recommended):
- `POST /madmin/impersonation/start` (email/id + optional reason)
- `POST /madmin/impersonation/stop`

This avoids relying on “member route” semantics and fits the search-bar UX.

#### **D. Session Expiry Enforcement**

Add a global guard (likely in `ApplicationController`) that:
- detects if impersonating
- checks `session[:impersonation_expires_at]` (or audit `expires_at`)
- if expired:
  - stop impersonating
  - finalize audit `ended_reason = expired`

#### **E. High-Risk Action Blocking**

Add an “impersonation risk gate” that can be applied via:

- `before_action` in relevant controllers (payments, account settings)
- or a shared concern used by multiple controllers

Example policy logic (conceptual):
- If `impersonating?` then block unless:
  - action is explicitly allowlisted
  - OR super admin passes an explicit “enable high risk actions” toggle (out of scope for v1)

**Important**: this should not weaken Pundit rules. It is additive.

### **UI / UX Changes**

#### **Admin UI: Search Bar**
- Location: madmin dashboard header (or madmin users page).
- Inputs:
  - single field (email or id)
  - optional reason
- Behavior:
  - show resolved user
  - confirm start

#### **Global Banner**
- Rendered in shared layout(s):
  - standard app layout
  - madmin layout (optional but recommended)
- Content:
  - “Acting as <email>”
  - “Stop” button
- Visual:
  - high-contrast, persistent, not dismissible except by stop

## 🧪 **Test Plan**

### **Unit Tests**
- [ ] `User#super_admin?` behavior
  - true for `admin@mellow.menu` (initially)
  - false otherwise
- [ ] `ImpersonationAudit` validations
  - requires `admin_user`, `impersonated_user`, `started_at`, `expires_at`

### **Controller / Request Tests**
- [ ] Super admin can start impersonation by email and id
- [ ] Non-super-admin cannot start impersonation (403)
- [ ] Starting impersonation creates an `ImpersonationAudit`
- [ ] Stop impersonation updates `ended_at` + `ended_reason`
- [ ] Expiry after 30 minutes auto-stops and updates audit

### **System / Integration Tests**
- [ ] Banner visible on pages while impersonating
- [ ] “Stop” action returns to admin identity
- [ ] High-risk endpoint blocked while impersonating
  - verify a payment/refund/portal endpoint returns 403 with a safe message

### **Security Tests (Must Have)**
- [ ] Ensure audit captures `ip_address` and `user_agent`
- [ ] Ensure CSRF protections remain intact
- [ ] Ensure impersonation cannot be started unless logged in and super admin

## 🎯 **Acceptance Criteria**

### **Must Have**
- [x] `User#super_admin?` exists and gates impersonation endpoints
- [x] Super admin can act as a user by searching email/id
- [x] Persistent banner displays acting-as state and provides stop
- [x] Session-only impersonation expires after 30 minutes
- [x] DB audit record created and finalized on stop/expiry
- [x] High-risk actions blocked by default while impersonating

### **Should Have**
- [x] Optional “reason” for impersonation stored in audit
- [x] Structured logging for start/stop/expire

### **Could Have**
- [x] Madmin UI for browsing/searching impersonation audits
- [x] Toggle to allow high-risk actions with extra confirmation + reason

---

**Created**: February 9, 2026
**Status**: Draft
**Priority**: High

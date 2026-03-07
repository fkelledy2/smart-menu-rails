# Bill Splitting Feature Request

## 📋 **Feature Overview**

**Feature Name**: Bill Splitting Among Order Participants
**Priority**: High
**Category**: Payment Processing & Customer Experience
**Estimated Effort**: Large (8-10 weeks)
**Target Release**: Q2 2026

## 🎯 **User Story**

**As a** diner participating in an `Ordr`
**I want to** split the bill with the other participants in the current order
**So that** each person can pay their share directly from the Smart Menu experience

**As an** employee
**I want to** review and manage a split plan when needed
**So that** the restaurant can collect the full amount with a clear audit trail and payment status visibility

## ✅ **Clarified Product Decisions**

- **Split methods in scope for first implementation**: equal, custom amount, percentage, and item-based splits
- **Who can configure splits**: any active `Ordrparticipant` in the diner flow and staff in the restaurant flow
- **How totals are allocated**: taxes, tips, and service charges are always distributed proportionally across the resulting shares
- **What happens after partial payment**: once any share is `pending` or `succeeded`, the split plan is frozen and cannot be structurally edited
- **Current implementation baseline**: `ordr_split_payments` and staff-triggered equal split already exist; this feature expands that foundation into a full split-plan workflow

## 📖 **Detailed Requirements**

### **1. Functional Scope**

#### **1.1 Split plan lifecycle**
- [ ] A split plan can only be created when the `Ordr` is in a payable state (`billrequested` initially)
- [ ] A split plan is attached to a single `Ordr`
- [ ] Only active order participants may be included in the split plan
- [ ] The split plan must expose a canonical status (`draft`, `validated`, `frozen`, `completed`, `failed`, `canceled` or equivalent)
- [ ] The plan becomes frozen immediately after any share begins payment processing or succeeds
- [ ] Once frozen, only non-structural actions are allowed (view status, pay remaining share, retry failed payment where supported)

#### **1.2 Supported split methods**
- [ ] **Equal split** across selected participants with cent-safe rounding
- [ ] **Custom amount split** with manual currency entry per participant
- [ ] **Percentage split** where participant percentages must total 100%
- [ ] **Item-based split** where `Ordritem`s are assigned to one or more participants
- [ ] **Hybrid support** for item-based plans that still proportionally allocate shared tax, tip, and service charge on top of assigned item value

#### **1.3 Authorization and actor rules**
- [ ] Staff can create, update, freeze, cancel, and monitor split plans from the restaurant management flow
- [ ] Any active diner participant can create or adjust a split plan from the customer-facing Smart Menu flow until the plan is frozen
- [ ] Diners can only pay their own assigned share
- [ ] Authorization rules must prevent one participant from editing or paying another participant's share outside approved flows

### **2. Calculation Rules**

#### **2.1 Totals and allocation**
- [ ] The source of truth is the current payable `Ordr` total, including subtotal, tax, tip, and service charge
- [ ] Split shares must sum exactly to the payable total after rounding
- [ ] Taxes, tips, and service charges are proportionally allocated across the final participant shares for all split methods
- [ ] Rounding rules must be deterministic and leave no unassigned or duplicated cents
- [ ] Validation must fail if the plan under-allocates or over-allocates the payable total

#### **2.2 Item-based rules**
- [ ] Because each `Ordritem` is currently one row per unit, item-based splitting should assign full item rows, not fractional quantities, unless schema changes are introduced explicitly
- [ ] An `Ordritem` must not be assigned more than once across participants unless a separate shared-item representation is intentionally introduced
- [ ] Unassigned items block validation and payment
- [ ] Item-based shares still receive proportional tax/tip/service allocation after item assignment is finalized

#### **2.3 Partial-payment behavior**
- [ ] If one participant has already started or completed payment, the split plan is frozen
- [ ] Remaining unpaid shares stay payable without recalculating already-paid shares
- [ ] The order reaches paid/closed only after all split shares succeed or another approved settlement path completes the remaining balance

### **3. UX Requirements**

#### **3.1 Customer Smart Menu flow**
- [ ] Add a customer-facing split bill entry point in the Smart Menu payment/bill flow
- [ ] Show all active participants and clearly identify the current participant
- [ ] Provide a method switcher for equal, custom, percentage, and item-based splits
- [ ] Show real-time recalculation of per-participant subtotal, tax, tip, service charge, and grand total
- [ ] Disable confirmation while the plan is invalid
- [ ] Once the plan is frozen, replace editing controls with read-only status and pay-share actions

#### **3.2 Staff flow**
- [ ] Extend the existing staff bill/payment UI rather than creating a parallel payment system
- [ ] Preserve the current equal split capability while migrating it onto the shared split-plan model/API
- [ ] Show participant payment statuses (`requires_payment`, `pending`, `succeeded`, `failed`, refunded/canceled if supported)
- [ ] Show clear validation state before staff can initiate share payments or share links

### **4. Payment Processing Requirements**

#### **4.1 Share-level payment execution**
- [ ] Each participant share must map to a payment record that can be processed independently
- [ ] Existing Stripe and Square checkout/session flows must support share-specific payment metadata
- [ ] The system must keep using provider webhooks to mark each share settled
- [ ] The order should emit `paid` only when all split shares are settled
- [ ] Failed share payments must not invalidate already successful shares

#### **4.2 Payment methods and receipts**
- [ ] Card-based provider checkout remains in scope for each participant share
- [ ] Restaurant-supported alternatives already present in the payment stack may be surfaced only if they can be tied to a single share without ambiguity
- [ ] Each successful share should have an identifiable receipt/payment reference
- [ ] Receipt UX may be split into implementation phases, but backend support for participant-level references is required

### **5. Auditability and State Projection**
- [ ] All split-plan create/update/freeze/pay events should be recoverable from persisted records and/or order events
- [ ] Staff must be able to see who configured the current split plan
- [ ] The current split plan and share statuses should be projectable into Smart Menu state / realtime updates where needed
- [ ] Webhook settlement must be idempotent and safe to replay

## 🔧 **Technical Specifications**

### **Reality Check: Existing Foundation**

- `OrdrPaymentsController#split_evenly` already creates `ordr_split_payments`
- `OrdrPaymentsController#checkout_session` already accepts `ordr_split_payment_id`
- Stripe and Square webhook ingestors already mark split payments as succeeded and emit `paid` only when all split payments settle
- The requirement should therefore extend `ordr_split_payments` and related payment flows, not introduce an unrelated `bill_splits` subsystem unless a clear migration path is defined

### **Recommended Data Model Direction**

#### **Keep and extend existing records**
- [ ] Use `ordr_split_payments` as the canonical payable-share record
- [ ] Add plan-level grouping metadata if one `Ordr` needs to preserve a current split plan version
- [ ] Add fields needed to represent method, allocation basis, actor, freeze state, and validation state
- [ ] Add optional share metadata for percentage/custom/item-based calculations

#### **Likely schema additions**
- [ ] Plan-level model/table or equivalent persisted grouping for one active split plan per `Ordr`
- [ ] Share allocation metadata per `ordr_split_payment` such as:
  - [ ] `split_method`
  - [ ] `position` / stable ordering
  - [ ] `base_amount_cents`
  - [ ] `tax_amount_cents`
  - [ ] `tip_amount_cents`
  - [ ] `service_charge_amount_cents`
  - [ ] `percentage_basis_points` for percentage splits
  - [ ] `locked_at` / frozen marker if not kept on plan
- [ ] Item assignment table tied to split share records and `ordritems`
- [ ] Audit fields for `created_by_user`, `updated_by_user`, and actor type when action is performed by participant vs staff

### **Recommended Service / API Shape**

#### **Backend services**
- [ ] Introduce a dedicated split-plan calculator/service object instead of embedding all logic in controllers
- [ ] Add validation service(s) for totals, participant eligibility, item assignment completeness, and frozen-plan enforcement
- [ ] Reuse the existing payment orchestration layer for provider-specific checkout session creation
- [ ] Reuse existing webhook ingestors for settlement, extending metadata parsing only as needed

#### **Controller / endpoint work**
- [ ] Keep the existing `split_evenly` endpoint working during migration
- [ ] Add/create a canonical create-or-update split-plan endpoint
- [ ] Add a read endpoint returning the current split plan and share statuses
- [ ] Add freeze/cancel endpoints only if plan state cannot be inferred cleanly from share/payment state
- [ ] Add customer-safe endpoints or route patterns if diner-facing split editing/payment should work outside authenticated staff routes

#### **Frontend work**
- [ ] Implement a shared UI/state contract so staff and customer flows consume the same split-plan payload shape
- [ ] Prefer Stimulus + existing Smart Menu JS patterns over a new frontend stack
- [ ] Ensure real-time updates can be reflected through the existing order state/broadcast architecture

## 🧪 **Required Test Checklist**

### **1. Model / service tests**
- [ ] Equal split calculator allocates all cents exactly across participants
- [ ] Custom split validator rejects totals not equal to payable order amount
- [ ] Percentage split validator rejects totals not equal to 100%
- [ ] Percentage split calculator handles cent rounding deterministically
- [ ] Item-based validator rejects unassigned items
- [ ] Item-based validator rejects duplicate item assignment when sharing is not explicitly supported
- [ ] Proportional allocation correctly distributes tax, tip, and service charge to each share
- [ ] Frozen-plan guard prevents structural edits after any share becomes `pending` or `succeeded`
- [ ] Authorization service/policy behavior distinguishes staff, current participant, and unrelated participant

### **2. Request / controller tests**
- [ ] Staff can create an equal split plan for a payable `Ordr`
- [ ] Staff can create custom, percentage, and item-based split plans
- [ ] Customer participant can create/update a split plan before freeze
- [ ] Unrelated participant cannot create/update another order's split plan
- [ ] Split creation/update fails for non-payable order statuses
- [ ] Split creation/update fails when totals do not match the order payable total
- [ ] Split creation/update fails when participant selection is invalid
- [ ] Split creation/update fails when attempting to edit a frozen plan
- [ ] Existing `checkout_session` flow rejects invalid `ordr_split_payment_id`
- [ ] Share-level checkout creates provider session/payment metadata linked to the correct share

### **3. Payment and webhook tests**
- [ ] Stripe webhook marks only the targeted share as succeeded
- [ ] Square webhook marks only the targeted share as succeeded
- [ ] Order is not marked `paid` while any share remains unpaid
- [ ] Order is marked `paid` once all shares succeed
- [ ] Webhook replay is idempotent for already-settled shares
- [ ] Failed share payment leaves remaining unpaid shares actionable

### **4. Integration / system behavior tests**
- [ ] Customer-facing split UI shows all four methods and live totals
- [ ] Staff-facing split UI reflects existing and newly-created split plans
- [ ] Frozen plan becomes read-only in both staff and customer flows after payment begins
- [ ] Payment status updates propagate to the visible order state
- [ ] Participant can pay only their own assigned share from the customer flow

## 📊 **Success Metrics**

### **1. Customer Satisfaction**
- [ ] Bill splitting usage rate among multi-participant orders
- [ ] Time to complete split setup and payment
- [ ] Reduction in "one person pays then gets reimbursed manually" support cases

### **2. Operational Efficiency**
- [ ] Reduction in staff intervention required to collect group payments
- [ ] Lower rate of split-payment mismatches or failed settlements
- [ ] Time from `billrequested` to fully paid for multi-party tables

### **3. Business Value**
- [ ] Increased completion rate for group checkout
- [ ] Reduced unpaid balances on large tables
- [ ] Improved conversion on customer self-serve payment flows

## 🚀 **Implementation Roadmap**

### **Phase 1: Normalize the existing foundation**
- [ ] Formalize current equal split flow as the first split-plan implementation
- [ ] Add canonical split-plan read model / payload shape
- [ ] Add freeze semantics and enforcement once payment begins
- [ ] Add/expand regression coverage for existing split-payment provider flows

### **Phase 2: Complete split method support**
- [ ] Add custom amount split creation/editing
- [ ] Add percentage split creation/editing
- [ ] Add item-based assignment and validation
- [ ] Add proportional tax/tip/service allocation to all methods

### **Phase 3: Customer and staff UX completion**
- [ ] Expose split setup in customer Smart Menu flow
- [ ] Unify staff and customer status presentation
- [ ] Add realtime state refresh / payment progress feedback
- [ ] Add participant-level receipt/reference UX

## 🎯 **Acceptance Criteria**

### **Must Have**
- [ ] An `Ordr` can be split across active participants using equal, custom, percentage, and item-based methods
- [ ] Any active participant and staff can configure the split before the plan is frozen
- [ ] Taxes, tips, and service charges are proportionally allocated across shares
- [ ] Split totals exactly equal the payable order total after rounding
- [ ] Each participant share can be paid independently through the existing provider integrations
- [ ] The split plan becomes read-only after any share enters payment processing or succeeds
- [ ] The `Ordr` becomes paid only when all split shares are settled

### **Should Have**
- [ ] Staff and customer interfaces both display live validation and per-share payment status
- [ ] Split-payment state is reflected in realtime order updates where available
- [ ] Each successful share has a retrievable payment reference / receipt reference

### **Could Have**
- [ ] Share links or QR shortcuts for each unpaid participant share
- [ ] Reusable split templates for common party scenarios
- [ ] Advanced refund workflows for partially-settled split plans

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

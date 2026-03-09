# Bill Splitting Feature Request

## 📋 **Feature Overview**

**Feature Name**: Bill Splitting Among Order Participants
**Priority**: High
**Category**: Payment Processing & Customer Experience
**Estimated Effort**: Multi-phase feature — core backend implemented, customer/staff UX completion still pending
**Target Release**: In progress

## 🚦 **Current Delivery Status**

- **Implemented now**: persisted `OrdrSplitPlan` + `OrdrSplitPayment` foundation, equal/custom/percentage/item-based calculation service, proportional tax/tip/service allocation, split-plan read/upsert endpoints, share-specific Stripe/Square checkout support, webhook-driven share settlement, and order-level paid detection after all shares succeed.
- **Partially implemented**: staff-oriented equal split flow is live via the existing order payments controller; canonical split-plan APIs exist but the customer-facing Smart Menu split UI and richer staff progress/status UX are still incomplete.
- **Still pending**: polished Smart Menu entry points, realtime customer progress UI, participant-facing management UX, receipt/reference UX, and broader end-to-end/system coverage.

## 🎯 **User Story**

**As a** diner participating in an `Ordr`
**I want to** split the bill with the other participants in the current order
**So that** each person can pay their share directly from the Smart Menu experience

**As an** employee
**I want to** review and manage a split plan when needed
**So that** the restaurant can collect the full amount with a clear audit trail and payment status visibility

## ✅ **Clarified Product Decisions**

- **Split methods supported in the backend now**: equal, custom amount, percentage, and item-based splits
- **Who can configure splits today**: authenticated staff and active diner participants with a current `Ordrparticipant` session
- **How totals are allocated**: taxes, tips, and service charges are distributed proportionally across the resulting shares
- **What happens after partial payment**: once any share is `pending` or `succeeded`, the split plan is frozen against structural edits
- **Current implementation baseline**: `ordr_split_payments` is no longer just a staff-triggered equal split helper; it now sits under a persisted `ordr_split_plan` model and shared calculator/upsert service

## 📖 **Detailed Requirements**

### **1. Functional Scope**

#### **1.1 Split plan lifecycle**
- [x] A split plan can only be created when the `Ordr` is in a payable state (`billrequested` currently)
- [x] A split plan is attached to a single `Ordr`
- [x] A split plan exposes a canonical persisted state via `OrdrSplitPlan` (`draft`, `validated`, `frozen`, `completed`, `failed`, `canceled`)
- [x] The plan becomes frozen after any share begins payment processing or succeeds
- [x] Once frozen, structural edits are blocked by the upsert service
- [ ] Only active order participants may be included in the split plan
- [ ] Completed/failed/canceled plan transitions should be driven consistently from settlement outcomes rather than inferred indirectly

#### **1.2 Supported split methods**
- [x] **Equal split** across selected participants with cent-safe rounding
- [x] **Custom amount split** with manual currency entry per participant
- [x] **Percentage split** where participant percentages must total 100%
- [x] **Item-based split** where `Ordritem`s are assigned to participants
- [x] **Hybrid support** for item-based plans that proportionally allocate tax, tip, and service charge on top of assigned item value

#### **1.3 Authorization and actor rules**
- [x] Staff can create and update split plans from the restaurant flow
- [x] Active diner participants can read/create/update a split plan through split endpoints until the plan is frozen
- [x] Diners can only pay their own assigned share in share-specific checkout flow
- [x] Authorization rules prevent unrelated sessions from editing or paying another order's split plan/share
- [ ] Staff-facing monitoring and override actions are not yet fully surfaced in the UI

### **2. Calculation Rules**

#### **2.1 Totals and allocation**
- [x] The source of truth is the payable `Ordr` total, including subtotal, tax, tip, and service charge
- [x] Split shares sum exactly to the payable total after rounding
- [x] Taxes, tips, and service charges are proportionally allocated across final participant shares for all supported split methods
- [x] Rounding is deterministic and leaves no unassigned or duplicated cents
- [x] Validation fails if custom/item/percentage inputs do not allo- [x] Validation fails if custom/item/peres- [x] Validation fails if custom/item/percentage inputs do not allo--based splitting assigns whole item rows
- [x] An `Ordritem` must not be assigned more than once across participants
- [x] Unassigned items block validation and payment
- [x] Item-based shares still receive proportional tax/tip/service allocation after item assignment is finalized
- [ ] Shared/fractional item handling is not implemented

#### **2.3 Partial-payment behavior**
- [x] If one participan- [x] If one participan- [xmpl- [x] If one participan- [x] If oro- [x] If one participan- [x] If one participan- [xmpl- [x] If one participan- [x] If oro- [x] If e order- [x] If one participan- [x] If one participan- [xm [ ] Explicit partial-settlement recovery UX remains to be built

### **3. UX Requirements**

#### **3.1 Customer Smart Menu flow**
- [ ] Add a customer-facing split bill entry point in the Smart Menu payment/bill flow
- [ ] Show all active participants and clearly identify the current participant
- [ ] Provide a method switcher for equal, custom, percentage, and item-based splits
- [ ] Show realtime recalculation of per-participant subtota- [ ] Show realtime recalculation of per-participant subtota- [ ] Show reail- [ ] Show realtime recalculation of per-particizen, replace editing controls with read-only status and pay-share actions

#### **3.2 Staff flow**
- [x] Extend the existing staff bill/payment backend instead of creating a parallel payment subsystem
- [x] Preserve the current equal split capability while moving it onto the shared split-plan model/API
- [ ] Show participant payment statuses (`requires_payment`, `pending`, `succeeded`, `failed`, refunded/canceled where supported`) in the main staff UI
- [ ] Show clear validation/progress state before staff initiates - [ ] Show clear validati### **4. Payment Processing Requirements**

#### **4.1 Share-level payment execution**
- [x] Each participant share maps to a payment record that can be processed independently
- [x] Existing Stripe and Squar- [x] Existing Stripe and Squar- [x] Existing Stripe and Squar- [x] Existing Stri use- [x] Existing Stripe and Squar- [x] Existing Stripe and Squar- [x] Existing Stripe and Squar- [x] Existing Stri use- [x] Existing Stripe and Squar- [x] Existing Stripe and Squar- [x] Existing Stripe and Squar- [x] Existing Stri use- [x] Existing Stripeer che- [x] Existing Strippe for each participant share
- [x] Share-specific provider references are persisted on split-payment/paym- [x] Share-specific provider references are persisted on split-payment/paym- [x] Share-specificanly
- [ ] Restaurant-supported alternative payment methods should only be exposed where they can be tied to one share unambiguously

### **5. Auditability and### **5. Auditability and### **5. Auditability and### **5. Auditability and### **5. Auditability and### **5. Auditability and### **5 at### **5. Auditability and### **5. Audit/ `updated_by_user`
- [x] Webhook settlement is expected to be idempotent and replay-safe through provider event ingestion
- [ ] Split-plan/share status is not yet fully projected into the customer-facing Smart Menu realtime state
- [ ] Rich audit/event visibility in staff UI is still pending

## 🔧 **Technical Specifications**

### **Current Foundation in Code**

- `OrdrPaymentsController#split_evenly` now delegates to `Payments::SplitPlanUpsertService` using `split_method: :equal`
- `OrdrPaymentsController#split_plan` provides a canonical read/upsert endpoint for split plans
- `OrdrPaymentsController#checkout_session` accepts `ordr_split_payment_id` and restricts customer sessions to paying only their own share
- `OrdrSplitPlan` persists `split_method`, `plan_status`, `participant_count`, `frozen_at`, and acto- `OrdrSplitPlan` persists `split_method`, `plan_status`, `participant_count`, `frozen_at`, and acto- `OrdrSplitPlan` persists `split_method`, `plan_status`, `participant_count`, `frozen_at`, and acto- `OrdrSplitPlans and `Ordritem`s
- Stripe and Square settlement flows already mark split payments as succeeded and emit order-level `paid` only when all shares settle

### **Data Model Direction**

#### **Already implemented**
- [x] `ordr_split_payments` is the canonical payable-share record
- [x] A plan-level grouping model exists via `ordr_split_plan`
- [x] Plan/share records include method, allocation, actor linkage, and freeze/lock state
- [x] Item assignment records exist for item-based split plans

#### **Potential follow-up schema work**
- [ ] Add explicit participant/session attribution when a diner, rather than staff user, authored the plan
- [ ] Add any plan-level metadata needed for customer-facing messaging or version history
- [ ] Add richer receipt/reference fields only if current provider IDs prove insufficient for UX needs

### **Service / API Shape**

#### **Backend services**
- [x] Dedicated split calculator/service objects exist (`Payments::SplitPlanCalculator`, `Payments::SplitPlanUpsertService`)
- [x] Validation for totals, assignment completeness, and frozen-plan enforcement is centralized in service/model logic
- [x] Existing provider-specific checkout orchestration is reused for share payments
- [x] Existing webhook ingestors are reused for settlement

#### **Controller / endpoint work**
- [x] The existing `split_evenly` endpoint remains supported
- [x] A canonical create/update split-plan endpoint exists
- [x] A read endpoint for the current split plan exists
- [ ] Freeze/cancel/completion endpoints are not exposed separately; current behavior is mostly inferred from share/payment state
- [ ] Customer-safe routes exist at the controller level, but the Smart Menu UI is not yet wired up to them

#### **Frontend work**
- [ ] Implement a shared UI/state contract so staff and customer flows consume the same split-plan payload shape
- [ ] Prefer Stimulus + existing Smart Menu JS patterns over a new frontend stack
- [ ] Reflect split-plan status through existing realtime order state/broadcast architecture

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
- [ ] Authorization behavior distinguishes staff, current participant, and unrelated participant

### **2. Request / controller tests**
- [x] Staff can create an equal split plan for a payable `Ordr`
- [ ] Staff can create custom, percentage, and item-based split plans
- [ ] Customer participant can create/update a split plan before freeze
- [ ] Unrelated participant cannot create/update another order's split plan
- [x] Split creation fails for non-payable order statuses
- [ ] Split creation/update fails when totals do not match the order payable total
- [ ] Split creation/update fails when participant selection is invalid
- [ ] Split creation/update fails when attemp- [ ] Split creation/update fails when attemp- kout_session` flow rejects invalid `ordr_split_payment_id`
- [x] Share-level checkout creates provider sess- [x] Share-level checkout creates provider sess- [x] Share-level checkout creates provider  Stripe webhook marks only the targeted share as succeeded
- [x] Square webhook marks only the targeted share as succeeded
- [x] Order is not marked `paid` while any share remains unpaid
- [x] Order is marked `paid` once all shares succeed
- [ ] Webhook replay is idempotent for already-settled shares
- [ ] Webhook replay is idempotent for already-settled shares
d
lble

### **4. Integration / system behavior tests**
- [ ] Customer-facing split UI shows all four methods and live totals
- [ ] Staff-facing split UI ref- [ ] Staff-facing split UI ref- [ ] Staff-facing splozen - [ ] Staff-facing split UI ref- [ ] Staff-facing split UI ref- [ ] Staff-facing ] Payment status updates propagate to the visible order state
- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ]g - [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ]g - [ ] Partic- [ ] Partic- [ ] Partie- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Partic- [ ] Parollect group payments
- [ ] Lower rate of split-payment mismatches or f- [ ] Lower rate of split-payment mismatches or f- o fully paid for multi-party tables

### **3. Business Value**
- [ ] Increased completion rate for group checkout
- [ ] Reduced unpaid balances on large tables
- [ ] Improved conversion on customer self-serve payment flows

## 🚀 **Implementation Roadmap**

### **Phase 1: Core backend foundation**
- [x] Formalize equal split on top of a persisted split-plan model
- [x] Add canonical split-plan payload shape and read/upsert endpoints
- [x] Add freeze semantics and enforcement once payment begins
- [x] Add regression coverage for core split-payment provider flows

### **Phase 2: API and validation completion**
- [ ] Expand automated coverage for custom, percentage, and item-based flows
- [ ] Harden participant-eligibility rules and freeze/error edge cases
- [ ] Add explicit lifecycle transitions where needed (`completed`, `failed`, `canceled`)
- [ ] Confirm idempotency/retry coverage across Stripe and Square se- [ ] Confirm idempotency/retry coverage across Stripe and Square se- [ ] Confirm idempotency/retry coverage across Stripe and Squareaff and customer status presen- [ ] Confirm idempotency/retry coverage acrossnt p- [ ] Confirm idempotency/retry coverage acr r- [ ] Confirm idempotency/retry coverage across Stripe and Squst- [ ] Confirm idempotency/retr split across participants using equal, custom, percentage, and item-based methods at the backend/service level
- [x] Staff and active participants can configure the split before the pl- [x] Staff and active participants can configure the split bse- [x] Staff and active participants can configure the split beforeit - [x] Staff and active participants can conf af- [x] Staff and active participants can configure the split before the pl-  the existing provider integrations
- [x] The split plan becomes read-only after any share enters payment processing or succeeds
- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomes paid only- [x] The `Ordr` becomlit templates for common party scenarios
- [ ] Advanced refund workflows for partially-settled split plans

---

**Created**: October 11, 2025
**Status**: In Progress — core backend flow shipped, UX and coverage expansion pending
**Priority**: High

# Onboarding Optimization

## Scope
From first contact on the website to a restaurant owner signed-in with a ready-to-use menu for staff and customers. This document maps the current flow and proposes improvements to reduce friction and time-to-value.

## Current Flow (A → Z)
- **A. Initial contact**
  - Public site and marketing pages.
  - Contact form → `ContactsController#create` (emails; analytics tracked).

- **B. Account creation & sign-in (Devise)**
  - User registers/logs in.
  - `User#after_create` sets default plan and creates an `OnboardingSession(status: :started)`.

- **C. Redirect to onboarding**
  - `ApplicationController#redirect_to_onboarding_if_needed` routes signed-in users without restaurants to the wizard.

- **D. Onboarding wizard (`OnboardingController`)**
  - Step 1: Account details → `account_created`.
  - Step 2: Restaurant details → `restaurant_details`.
  - Step 3: Plan selection → updates `User#plan`, `plan_selected`.
  - Step 4: Menu creation (name + items array). On success:
    - Enqueue `RestaurantOnboardingJob` to create Restaurant, Menu, defaults, owner employee, items, availabilities.
    - Enqueue `SmartMenuGeneratorJob` to create SmartMenus.
    - Mark `menu_created`, advance to Step 5.
  - Step 5: Completion (no QR yet, JSON endpoint can indicate readiness).

- **E. Post-onboarding menu import (optional)**
  - PDF OCR import via `OcrMenuImportsController#create` → async processing.

## Strengths
- **Guided wizard** with analytics per step.
- **Background orchestration** for Restaurant/Menu/SmartMenus.
- **Default plan assignment** to reduce initial decisions.
- **Live smartmenu state** via ActionCable for staff/customers.

## Pain Points / Friction
- **Plan selection during onboarding** adds early friction before value.
- **Menu creation requires manual entry**; CSV/PDF import sits outside the core wizard.
- **Async job visibility**: No progress/ready indicators in the UI.
- **No instant demo**: Users can’t immediately try a working menu without manual data.
- **Next steps unclear**: Links to staff/customer views/QR aren’t surfaced at completion.
- **Staff onboarding not integrated** at completion.
- **Potential UI flicker** in dynamic CTAs before state hydration.

## Recommendations

### Quick Wins (low effort, high impact)
- **Defer or skip plan selection in onboarding**
  - Default to free/trial; surface upgrade later in billing.
- **Add a Demo Menu option in Step 4**
  - Offer 2–3 templates or a generic sample to go live instantly.
- **Integrate CSV/Excel upload in Step 4**
  - Quick mapping + preview; commit to menu items.
- **Expose background job progress and readiness**
  - Poll onboarding status on Step 5 (JSON already supported) and show:
    - Restaurant ✓  Menu ✓  SmartMenus ✓
  - Provide action buttons: Open Staff View, Open Customer View, Copy QR/Links.
- **Staff invite CTA on completion**
  - One-click owner → staff invitation flow.
- **Gate dynamic CTAs until state hydration**
  - Continue the pattern to avoid flicker and confusion.

### Medium-Term Improvements
- **OCR import option inside Step 4**
  - Queue OCR, show status and a merge review when ready.
- **Passwordless/SSO** (magic link, Google/Apple) to reduce login friction.
- **Dashboard checklist** post-onboarding
  - “Add logo”, “Set opening hours”, “Create table QR sets”, “Invite staff”, etc.
- **Enhanced analytics funnel**
  - Track step drop-offs, A/B test skipping plan, measure TTFM (time to first menu) and TTFO (time to first order).

### Strategic Upgrades
- **Template-driven onboarding** by cuisine/type (localized, with sections/items/images).
- **Guided staff onboarding** right after completion (roles, device setup, training tips).
- **Streamlined menu editor UX** (inline edits, bulk ops, availability tools).

## Proposed Implementation Order
- **Phase 1 (1–2 sprints)**
  - Skip/auto-select plan; add Demo Menu option.
  - CSV/Excel import in Step 4.
  - Job progress UI + completion CTAs (staff/customer/QR).
  - Staff invite CTA.
- **Phase 2**
  - OCR import within Step 4 with status/merge review.
  - Magic link/SSO.
  - Dashboard checklist.
- **Phase 3**
  - Templates by cuisine/type.
  - Menu editor & staff management polish.

## KPIs to Monitor
- Onboarding step conversion and drop-offs.
- Time to first menu (TTFM), time to first order (TTFO).
- Import success/correction rates (CSV/OCR).
- Plan upgrade rate post-onboarding.
- Support tickets related to onboarding/menus.

## References (Code Pointers)
- Onboarding session: `app/models/onboarding_session.rb`
- User defaults & onboarding: `app/models/user.rb`
- Wizard controller: `app/controllers/onboarding_controller.rb`
- Redirect to onboarding: `app/controllers/application_controller.rb#redirect_to_onboarding_if_needed`
- Restaurant & menu creation job: `app/jobs/restaurant_onboarding_job.rb`
- OCR import: `app/controllers/ocr_menu_imports_controller.rb`

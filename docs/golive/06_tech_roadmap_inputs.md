# Technical Roadmap Inputs (Marketing-Driven)
## mellow.menu Go-To-Market Plan — Document 06

This document flags all marketing requirements that depend on engineering work. These are not marketing tasks — they are product backlog items that unlock specific marketing capabilities. Each item should be reviewed with the product team and prioritised accordingly.

**Format:** Each item includes the marketing impact, priority, and suggested backlog framing.

---

## Critical — Required Before Public Launch (Phase 2)

### T1 — Demo Booking Form + Calendly Integration
**Status:** Largely implemented — 3 outstanding tasks before this is fully live

**What has already been built:**
- `DemoBooking` model with all required fields (restaurant_name, contact_name, email, phone, restaurant_type, location_count, interests, calendly_event_id, conversion_status)
- `DemoBookingsController#create` — JSON API, rate-limited via Rack::Attack
- `DemoBookingMailer#confirmation` — branded email delivered async via Sidekiq
- `DemoBooking#calendly_booking_url` — builds pre-filled Calendly URL from `CALENDLY_EVENT_URL` env var
- `_demo_booking_modal.html.erb` — full responsive form with GDPR privacy link
- Stimulus `demo-booking` controller — form submit, validation, error handling, inline Calendly widget on success
- Video analytics endpoint + `VideoAnalytic` model
- Admin views at `admin/demo_bookings` (index + show)
- **Full Calendly webhook pipeline** (beyond original spec): `Crm::CalendlyWebhookVerifier`, `Crm::CalendlyEventHandler`, `Crm::ProcessCalendlyWebhookJob`, `CrmLead` pipeline with `LeadTransitionService` and `LeadAuditWriter`

**Outstanding tasks:**
1. ~~**Set `CALENDLY_EVENT_URL` env var in production**~~ — **DONE** (set in Heroku, 2026-04-01)
2. ~~**Load Calendly JS on marketing pages**~~ — **DONE** (added async to `app/views/layouts/marketing.html.erb`, 2026-04-01)
3. ~~**Wire up the homepage hero CTAs and confirm `/demo` page exists**~~ — **DONE** (homepage renders `_demo_booking_modal`, hero CTA links to `demo_path`, `/demo` standalone page exists with full content and modal, 2026-04-01)

**Status: T1 is LIVE.** All three outstanding tasks are complete. The demo booking form is fully operational: lead capture → confirmation email → Calendly inline widget.

**Remaining recommendation:** Set `CALENDLY_WEBHOOK_SIGNING_KEY` in Heroku if not already done. This enables the webhook pipeline (`Crm::CalendlyWebhookVerifier`) to verify Calendly event payloads and auto-advance CRM leads to `demo_booked` stage when a prospect books a slot.

---

### T2 — Public-Facing Pricing Page
**What is needed:** A pricing page at mellow.menu/pricing that:
- Displays the Starter, Pro, Business, and Enterprise plan tiers
- Shows monthly and annual pricing
- Has a feature comparison table
- Has "Start Free Trial" and "Book Demo" CTAs per plan
- Is connected to the live `plans` table data

**Marketing impact:** Hiding pricing is one of the top reasons B2B SaaS visitors don't convert. Restaurant owners make buying decisions faster when they can self-qualify on price. The pricing page is the second-highest converting page on any SaaS marketing site.
**Priority:** Critical — must be live before Phase 2
**Suggested backlog item:** "Build public pricing page at /pricing with plan comparison table and live plan data from the database"

---

### T3 — Free Trial Activation (No Credit Card Required)
**What is needed:** The ability for a restaurant to sign up and access a fully functional trial of the Professional plan for 14–30 days without entering payment details. After the trial ends, features should be gated and the user prompted to upgrade.
**Requires:** Usage-gated feature flags (Flipper is already in the stack), trial state on the `restaurant_subscription` or `userplan` model, and automated trial expiry emails.

**Marketing impact:** "No credit card required" is the highest-converting change a SaaS can make to its free trial flow. It reduces signup friction by 20–40% in most SaaS benchmarks. Without it, the conversion funnel relies entirely on demo booking, which is slower and more resource-intensive.
**Priority:** High — should be live for Phase 2 launch
**Suggested backlog item:** "Implement 14-day free trial flow with no credit card required; gate features on trial expiry via Flipper; trigger trial expiry email sequence"

---

### T4 — Cookie Consent and GDPR Compliance Banner
**What is needed:** A GDPR-compliant cookie consent banner on the marketing site (mellow.menu) that:
- Presents at first visit for all EU visitors
- Allows users to accept, decline, or customise cookie categories (functional, analytics, marketing)
- Stores consent preference
- Blocks GA4 and Hotjar from loading until consent is given

**Marketing impact:** Required by law before collecting analytics data from EU visitors. Without it, any analytics data collected could be legally challenged and GA4 data will be incomplete/misleading.
**Priority:** Critical — must be live before any EU traffic
**Suggested backlog item:** "Implement GDPR-compliant cookie consent on mellow.menu marketing pages using a consent management library (e.g. Cookiebot, CookieYes, or custom implementation)"

---

### T5 — "Powered by mellow.menu" Branding on Public Menu Pages
**What is needed:** Every public menu page (the page guests see when they scan a QR code) should display a tasteful "Powered by mellow.menu" badge that links back to mellow.menu.

**Marketing impact:** This is the core product-led growth (PLG) viral loop. Every restaurant guest who scans a QR code is a potential future customer (they may be a restaurant owner, or they tell their restaurant-owner friend). At 1,000 restaurants, this creates millions of branded impressions per month at zero marginal cost. This is how me&u, Bopple, and Mr Yum grew virally in Australia.
**Priority:** High — should be live from Phase 1 (ideally in T&Cs as an attribution right on free/Starter tiers)
**Suggested backlog item:** "Add 'Powered by mellow.menu' badge with link to mellow.menu on all public smartmenu pages; make it removable for Business/Enterprise plans only"

---

## High Priority — Before or Shortly After Public Launch

### T6 — SEO Structured Data on Public Menu Pages (schema.org/Menu)
**What is needed:** Public menu pages (the pages guests see when they scan a QR code at a restaurant) should include structured data markup using schema.org/Menu, schema.org/MenuItem, and schema.org/FoodEstablishment.

**Marketing impact:** Enables Google to index and display restaurant menus in rich search results ("menu" carousels in Google Search). This creates a powerful SEO flywheel: the more restaurants use mellow.menu, the more menu content Google indexes, the more search traffic both the restaurants and mellow.menu receive. This is a compounding advantage that builds over time.
**Priority:** High
**Suggested backlog item:** "Add schema.org/Menu structured data (JSON-LD) to all public smartmenu pages, including MenuItem with name, description, price, and image"

---

### T7 — In-App Onboarding Checklist
**What is needed:** When a new restaurant signs up, show a clear onboarding checklist (5–7 steps) that guides them to:
1. Create their first menu
2. Add at least 5 menu items
3. Set up their first QR code
4. Preview the guest-facing menu
5. Connect a payment provider

**Marketing impact:** Activation rate (the % of signups who complete a meaningful first step) is the most important SaaS metric in the first 30 days. Without an in-app guide, most signups will drop off before experiencing the core value. The `onboarding_sessions` model is already in the data model — the in-app flow needs to surface and track completion.
**Priority:** High — critical for trial activation
**Suggested backlog item:** "Build in-app onboarding checklist component for new restaurant signups using the existing onboarding_sessions model; track completion per step; trigger step-specific email on incomplete steps at Day 3"

---

### T8 — Demo Mode / Interactive Preview Without Signup
**What is needed:** A publicly accessible demo restaurant menu on mellow.menu/demo or embedded on the homepage that visitors can interact with (browse, see language switching, see ordering flow) without creating an account.

**Marketing impact:** The best way to sell mellow.menu is to let restaurant owners experience it as a guest. An interactive demo removes the "I want to see it before I sign up" objection entirely. This is a strong conversion lever for cold traffic from Product Hunt, press, and SEO.
**Priority:** High — for Phase 2 launch
**Suggested backlog item:** "Create a read-only 'demo restaurant' smartmenu page accessible at mellow.menu/demo with sample menu, language switching, and simulated ordering flow (no real orders processed)"

---

### T9 — Testimonials Management in Admin
**What is needed:** The `testimonials` table already exists in the data model. The admin panel needs a UI to:
- Create and manage testimonial records (restaurant name, contact name, quote, rating, photo)
- Toggle testimonials as visible/hidden on the marketing site
- Display testimonials on the homepage/pricing page via a live query

**Marketing impact:** Social proof is the #1 conversion driver on B2B SaaS landing pages. Testimonials must be live on the homepage before Phase 2 launch. Currently there is no way to manage them without direct database access.
**Priority:** High — needed for Phase 2 launch
**Suggested backlog item:** "Build admin UI for creating and managing Testimonial records; surface active testimonials on homepage via a Turbo/partial or static query"

---

## Medium Priority — Month 3–6

### T10 — Referral Programme Tracking System
**What is needed:** A referral programme requires:
- Unique referral link/code per restaurant
- Tracking of signups originating from referral links
- Attribution of converted customers to their referring restaurant
- Automated credit (account credit or payment reduction) when a referred restaurant passes the qualifying threshold (e.g. 3 months paid)

**Marketing impact:** Referral programmes are the highest-ROI acquisition channel at scale (CAC EUR 30–80 vs. EUR 150–400 for paid). Restaurant owners trust recommendations from other restaurant owners above all other sources.
**Priority:** Medium — target Month 6–7
**Suggested backlog item:** "Build referral tracking system: unique referral codes per restaurant, referral attribution on signup, automated credit when referred restaurant reaches 3 months paid; admin dashboard for referral programme management"

---

### T11 — AI Pricing Recommendation Email Digest
**What is needed:** A weekly automated email to restaurant owners containing:
- Their top 3 AI-generated pricing or menu recommendations
- One insight from their margin analytics
- A CTA to act on the recommendation in the dashboard

**Marketing impact:** Drives weekly re-engagement with the product. Reduces churn by reminding customers of value. Creates a stream of specific, citable outcomes that can be turned into testimonials and case studies. Customers who act on recommendations and see results become advocates.
**Priority:** Medium — target Month 4
**Suggested backlog item:** "Build weekly AI insights email digest for restaurant owners: summarise top 3 recommendations from menu optimisation engine; deliver via Sidekiq-scheduled mailer"

---

### T12 — Public "Menu Health Score" or Shareable Menu Card
**What is needed:** A shareable card or badge that restaurants can post on social media showing a summary of their mellow.menu metrics (e.g. "12 languages, 847 orders this month, 94% satisfaction") — auto-generated by the platform.

**Marketing impact:** Creates organic viral distribution. Restaurant owners sharing their own metrics are advertising mellow.menu to their followers at zero cost. This is a known SaaS growth tactic (see Spotify Wrapped, Stripe revenue milestones).
**Priority:** Medium — target Month 5–6
**Suggested backlog item:** "Build monthly shareable 'menu stats card' as an auto-generated image or shareable URL with key restaurant metrics; trigger an email to restaurant owners on the 1st of each month with a link to their card"

---

### T13 — CSV Export for Restaurant Analytics
**What is needed:** Restaurant owners should be able to export their order history, revenue, and menu performance data as a CSV file from the admin dashboard.

**Marketing impact:** Restaurant owners who use the analytics export to share data with their accountant or operations manager become deeply embedded in the platform. It also enables the ROI case study narrative: "I showed my accountant the margin data and we made changes that added EUR 800/month."
**Priority:** Medium
**Suggested backlog item:** "Add CSV export for order history, revenue totals, and menu item performance from restaurant analytics dashboard"

---

### T14 — Branded Receipt Email
**What is needed:** Post-order, send a branded email receipt to guests who ordered via mellow.menu.
**Requires:** The `receipt_delivery` model exists — the mailer and front-end opt-in need to be built.

**Marketing impact:** A receipt with "Powered by mellow.menu" drives awareness among restaurant guests, reinforces the brand, and creates a direct marketing asset the restaurant can use. Also a strong onboarding milestone — "your first receipt was just sent."
**Priority:** Medium — specced as feature request
**Suggested backlog item:** "Build branded receipt email sent to guests after order completion; include 'Powered by mellow.menu' footer; allow restaurant to add custom message"

---

## Lower Priority — Month 6+

### T15 — White-Label / Branded Plan
**What is needed:** Enterprise customers should be able to brand the guest-facing menu pages with their own logo, colours, and domain (e.g. menu.theirrestaurant.com) instead of the mellow.menu branding.

**Marketing impact:** Required to win enterprise and franchise contracts. Enables a separate "white-label partner" revenue stream for agencies and consultants who want to resell under their own brand.
**Priority:** Low for Phase 1–2; High for enterprise sales (Month 9+)
**Suggested backlog item:** "Build white-label configuration for Enterprise plan: custom subdomain, custom logo/colours on public menu pages, remove mellow.menu branding"

---

### T16 — API Documentation and Developer Portal
**What is needed:** A public API documentation site (api.mellow.menu or docs.mellow.menu) for partners, integrators, and enterprise customers who want to connect mellow.menu to their own systems.

**Marketing impact:** Required for POS integrations, delivery platform partnerships, and enterprise technical evaluations. A well-documented API also attracts developer ecosystem attention and inbound links.
**Priority:** Low for launch; Medium from Month 9
**Suggested backlog item:** "Create public API documentation portal with authentication guide, endpoint reference, and code examples for key use cases (menu management, order retrieval)"

---

## Summary Table

| Item | Marketing Unlock | Priority | Target Phase |
|---|---|---|---|
| T1 Demo booking form | Sales pipeline | Critical | Phase 0 |
| T2 Public pricing page | Self-serve conversion | Critical | Phase 0 |
| T3 Free trial (no credit card) | Trial signups | High | Phase 2 |
| T4 Cookie consent | Legal compliance + analytics data | Critical | Phase 0 |
| T5 "Powered by mellow.menu" PLG | Viral brand exposure | High | Phase 1 |
| T6 SEO structured data on menus | Organic traffic flywheel | High | Phase 2 |
| T7 In-app onboarding checklist | Activation rate | High | Phase 2 |
| T8 Demo mode / interactive preview | Cold traffic conversion | High | Phase 2 |
| T9 Testimonials admin UI | Social proof on landing page | High | Phase 2 |
| T10 Referral programme tracking | Referral channel | Medium | Month 6–7 |
| T11 AI digest email | Churn reduction + case studies | Medium | Month 4 |
| T12 Shareable menu stats card | Organic virality | Medium | Month 5–6 |
| T13 Analytics CSV export | Retention + case study data | Medium | Month 4 |
| T14 Branded receipt email | Guest brand exposure | Medium | Month 4 |
| T15 White-label plan | Enterprise sales | Low (now) | Month 9+ |
| T16 API docs | Partner + enterprise sales | Low (now) | Month 9+ |

---

*Priority: High | Owner: Founder to triage with engineering team | Effort: Varies per item*

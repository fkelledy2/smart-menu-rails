# Pre-Launch Readiness Checklist
## mellow.menu Go-To-Market Plan — Document 02

**Target: Complete all High priority items before public launch (Phase 2)**
**DNS status: Live as of 2026-03-31**

---

## Section 1 — Brand and Messaging Foundations

| Task | Priority | Effort | Owner | Status |
|---|---|---|---|---|
| Finalise positioning statement and value props (see 01_positioning.md) | High | 1 day | Founder | - |
| Write homepage headline, subheadline, and hero copy | High | 1 day | Founder | - |
| Define brand colour palette and typography (if not already codified) | High | 2 days | Designer/Founder | - |
| Create mellow.menu logo lockup (full + icon versions) | High | 3 days | Designer | - |
| Define the 3 core use-case narratives for marketing (multilingual, AI pricing, table ordering) | High | 1 day | Founder | - |
| Write tone of voice guide (2-page internal doc) | Medium | 1 day | Founder | - |
| Create a brand asset folder (logos, colours, fonts) accessible to any contractor | Medium | 1 day | Founder | - |

---

## Section 2 — Website and Landing Pages (mellow.menu)

| Task | Priority | Effort | Owner | Notes |
|---|---|---|---|---|
| Build homepage with hero, value props, feature sections, social proof, and CTA | High | 1–2 weeks | Developer/Agency | Must be live before Phase 2 |
| Build pricing page with plan comparison table | High | 3–5 days | Developer | Pull plan data from `plans` table; Starter/Pro/Business/Enterprise |
| Build demo booking page (/demo) with form + Calendly embed | High | 3 days | Developer | `DemoBooking` model already specced (see homepage-demo-booking-feature-request.md) |
| Implement demo booking form on homepage (inline section + standalone /demo page) | High | 2 days | Developer | Calendly integration; confirmation email via `DemoBookingMailer` |
| Build /features page (or expand homepage sections) covering all major capabilities | Medium | 3 days | Developer | Pull from 05_feature_marketing_map.md |
| Add testimonials section (placeholder initially; real content after soft launch) | Medium | 1 day | Developer | `testimonials` table already exists |
| Add customer logo strip (placeholder; real logos after signing first restaurants) | Medium | 1 day | Developer | - |
| Build /about page (founder story, mission) | Medium | 1 day | Founder | - |
| Ensure all pages are mobile-responsive and load under 3 seconds | High | 2 days | Developer | Core Web Vitals check |
| Set up custom 404 and 500 error pages with brand styling | Low | 0.5 day | Developer | - |
| Add blog/resources section (even if empty initially) | Medium | 1 day | Developer | Needed for SEO content later |
| Implement cookie consent banner (GDPR-compliant) | High | 1 day | Developer | Required before EU traffic |
| Add schema.org/Restaurant and Organization structured data to homepage | Medium | 1 day | Developer | SEO foundation |
| **Flag for engineering:** Public menu pages need schema.org/Menu structured data | High | - | Product team | See 06_tech_roadmap_inputs.md |

---

## Section 3 — Social Proof and Credibility Assets

| Task | Priority | Effort | Owner | Notes |
|---|---|---|---|---|
| Recruit 5 anchor restaurants for soft launch (no cost or heavily discounted) | High | 1–2 weeks | Founder | These become your first testimonials and case studies |
| Create a "pilot partner" agreement template (short, friendly, not legal heavy) | High | 1 day | Founder | Explains what you need from them in exchange for free/discounted access |
| Capture 3 written testimonials from pilot restaurants | High | 2–3 weeks | Founder | Brief the restaurant owners on what makes a useful testimonial (specifics) |
| Photograph 2–3 pilot restaurants using mellow.menu QR codes in situ | Medium | 1 day | Founder | Use these as lifestyle photography on the homepage |
| Create one 2-minute screen-capture product walkthrough video | High | 2 days | Founder | Essential for homepage "Watch Demo" CTA; Loom is fine for v1 |
| Write one mini case study (500 words) from the first anchor restaurant | Medium | 3 days | Founder | Publish as a blog post; use in sales emails |
| Document 3 specific ROI metrics from pilot restaurants (e.g. "saved 4 hours/week on reprints") | High | Ongoing | Founder | These become sales ammunition |

---

## Section 4 — Legal and Compliance

| Task | Priority | Effort | Owner | Notes |
|---|---|---|---|---|
| Draft and publish Terms and Conditions for mellow.menu | High | 3–5 days | Lawyer/Founder | Must cover SaaS subscription, data processing, acceptable use |
| Draft and publish Privacy Policy | High | 3–5 days | Lawyer/Founder | GDPR-compliant; cover all data collected (menu data, order data, user data) |
| Add GDPR Data Processing Agreement (DPA) template for restaurant customers | High | 2 days | Lawyer | Restaurants process their own customers' data through your platform |
| Implement cookie consent and preference manager | High | 1–2 days | Developer | Functional, analytics, and marketing cookie categories at minimum |
| Draft refund and cancellation policy | High | 1 day | Founder | Must be clear on pro-rata refunds, notice periods |
| Confirm PCI DSS compliance statement (you don't store card data — Stripe/Square do) | High | 1 day | Founder | Add to website security/compliance page |
| Register as a data controller with the relevant data protection authority (e.g. DPC in Ireland) | High | 1 week | Founder | Required for GDPR if operating in EU |
| Add "Powered by mellow.menu" attribution rights in T&Cs | Medium | 0.5 day | Founder | Enables viral brand exposure on public menu pages |
| Create GDPR data deletion request procedure | Medium | 2 days | Developer+Founder | Must be actionable, not just promised |
| Document data retention policies | Medium | 1 day | Founder | How long order data, personal data, and analytics data are retained |

---

## Section 5 — Analytics and Tracking

| Task | Priority | Effort | Owner | Notes |
|---|---|---|---|---|
| Install Google Analytics 4 (GA4) on mellow.menu marketing pages | High | 0.5 day | Developer | Separate from the app; marketing site only |
| Configure GA4 conversion events: demo_booking_submitted, signup_started, pricing_page_viewed | High | 1 day | Developer | These are your primary funnel metrics |
| Install Hotjar (or Microsoft Clarity — free) on marketing pages | Medium | 0.5 day | Developer | Session recordings for UX feedback |
| Define UTM parameter framework for all marketing channels | High | 0.5 day | Founder | e.g. utm_source=linkedin, utm_medium=organic, utm_campaign=launch-q2-2026 |
| Create UTM link builder spreadsheet for the team | Medium | 0.5 day | Founder | Shared Google Sheet; prevents UTM chaos |
| Set up Google Search Console for mellow.menu | High | 0.5 day | Founder | Index verification, crawl errors, keyword data |
| Set up basic conversion tracking in Stripe dashboard (MRR, new customers, churn) | High | 0.5 day | Founder | Stripe Radar + Revenue dashboards |
| Create a weekly metrics review template (MRR, trials, demos booked, activation rate) | Medium | 0.5 day | Founder | Simple spreadsheet or Notion doc |
| Configure Sentry for production error monitoring (already in stack) | High | Already done | Dev | Confirm alerting is routed to founder |

---

## Section 6 — Customer Support Infrastructure

| Task | Priority | Effort | Owner | Notes |
|---|---|---|---|---|
| Create a help documentation site (Notion, Intercom, or GitBook) | High | 1 week | Founder | Minimum: getting started guide, how to import a menu, how to set up QR codes |
| Write onboarding email sequence (5 emails over 14 days post-signup) | High | 3 days | Founder | See suggested sequence below |
| Set up a support email address (support@mellow.menu or via Intercom) | High | 0.5 day | Founder | Must be monitored daily at launch |
| Create an in-app onboarding checklist for new restaurants (first 5 steps) | High | 3 days | Developer | Ties to `onboarding_sessions` model already in place |
| Write FAQ covering top 10 anticipated questions | Medium | 1 day | Founder | Publish on website; use in sales emails |
| Set up a shared inbox or ticketing tool for support (Intercom free tier, or Missive) | Medium | 0.5 day | Founder | Avoid personal email for support |
| Create a template for onboarding call agenda (45-minute session) | Medium | 1 day | Founder | Used for every new restaurant in Phase 1 |
| Define SLA for support response: 4 hours during business hours for paying customers | Medium | 0.5 day | Founder | Publish in T&Cs |

### Onboarding Email Sequence (Suggested)

| Email | When | Subject | Goal |
|---|---|---|---|
| 1 | Immediately on signup | "Welcome to mellow.menu — let's get your menu live" | Drive to first menu creation |
| 2 | Day 2 (if no menu created) | "Need a hand getting started? Here's the 5-minute route" | Remove friction; link to OCR import |
| 3 | Day 5 | "Your menu is live — now set up your QR code" | Drive to QR activation |
| 4 | Day 10 | "See what your customers see (and what it means for your revenue)" | Show analytics; prompt first pricing review |
| 5 | Day 14 | "How's mellow.menu working for you?" | NPS survey + offer a 30-minute review call |

---

## Section 7 — Pricing Strategy

| Task | Priority | Effort | Owner | Notes |
|---|---|---|---|---|
| Finalise monthly and annual pricing for Starter, Pro, Business tiers | High | 2 days | Founder | See recommended pricing below |
| Decide on annual discount (typically 15–20% for annual prepay) | High | 0.5 day | Founder | - |
| Decide on free trial duration (14 or 30 days recommended) | High | 0.5 day | Founder | 14 days is standard; 30 days for complex onboarding |
| Define what features are included in each plan | High | 1 day | Founder | Map against `features_plans` table |
| Publish pricing page before Phase 2 launch | High | 3 days | Developer | Transparency builds trust; hiding pricing hurts conversion |
| Decide on a "no credit card required" trial policy | High | 0.5 day | Founder | Strong recommendation: no card required; reduces friction significantly |
| Create a one-page pricing summary for sales calls | Medium | 0.5 day | Founder | PDF or Notion page |
| Define Enterprise pricing approach (custom quote vs. published floor) | Medium | 1 day | Founder | Recommend publishing "from EUR X/month" to qualify prospects |

### Recommended Pricing Framework (for consideration)

| Plan | Monthly | Annual (equiv.) | Key Limits |
|---|---|---|---|
| Starter | EUR 49/mo | EUR 39/mo | 1 location, up to 1 menu, basic analytics |
| Professional | EUR 99/mo | EUR 79/mo | 1 location, unlimited menus, AI pricing, multilingual |
| Business | EUR 199/mo | EUR 159/mo | Up to 5 locations, all features, priority support |
| Enterprise | Custom | Custom | 5+ locations, white-label, dedicated CSM |

*This is a starting hypothesis. Validate with 5 discovery conversations before publishing.*

---

## Pre-Launch Gate Criteria

Before moving to Phase 2 (public launch), the following must ALL be true:

- [ ] Homepage is live on mellow.menu with working CTAs
- [ ] Pricing page is live
- [ ] Demo booking form is live and connected to Calendly
- [ ] Terms & Conditions and Privacy Policy are published
- [ ] Cookie consent banner is active
- [ ] GA4 conversion events are firing correctly
- [ ] Support email is monitored
- [ ] At least 2 anchor restaurants are live and using the platform
- [ ] Onboarding email sequence is active
- [ ] At least 1 written testimonial is captured

---

*Priority: High | Owner: Founder | Effort: 3–4 weeks total*

# KPIs and Success Metrics
## mellow.menu Go-To-Market Plan — Document 07

---

## 1. North Star Metric

**Monthly Recurring Revenue (MRR)**

MRR is the single metric that tells you whether the business is growing. Everything else is a leading indicator that explains why MRR is where it is.

Secondary north star: **Number of Active Paying Restaurants** (because MRR can look healthy if one large customer is paying, but breadth of customer base indicates real product-market fit)

---

## 2. MRR and Restaurant Count Targets

| Milestone | MRR Target | Paying Restaurants | Avg Revenue/Restaurant | Notes |
|---|---|---|---|---|
| End of Phase 1 (May 2026) | EUR 0–500 | 3–5 | EUR 0–99 (pilot pricing) | Some pilots may be free |
| Month 3 (Jun 2026) | EUR 1,500 | 10 | EUR 150 avg (mix of plans) | First paying customers |
| Month 6 (Sep 2026) | EUR 5,000 | 30–35 | EUR 145 avg | Starter/Pro mix |
| Month 9 (Dec 2026) | EUR 8,000 | 55–60 | EUR 140 avg | Some Business plan adds |
| Month 12 (Mar 2027) | EUR 12,000–15,000 | 80–100 | EUR 150 avg | First enterprise deal possible |

### Assumptions Behind Targets
- Average plan mix: 50% Starter (EUR 49), 35% Professional (EUR 99), 15% Business (EUR 199)
- Blended average revenue per restaurant: ~EUR 90–100/month
- Monthly churn rate: 5% (ambitious but achievable with strong onboarding and product quality)
- Note: if you close the first enterprise deal (EUR 500–1,000+/month), targets will accelerate

### What These Targets Mean
- **EUR 12k MRR at Month 12 = EUR 144k ARR** — this is a meaningful milestone for fundraising conversations and demonstrates repeatable growth
- **100 restaurants** is the proof-of-scale threshold — enough to show product-market fit across multiple segments and geographies

---

## 3. Funnel Metrics (Leading Indicators)

These are the metrics that predict whether you will hit the MRR targets. Track weekly.

### Website and Top of Funnel

| Metric | Month 1 Target | Month 6 Target | Month 12 Target | Tool |
|---|---|---|---|---|
| Unique visitors to mellow.menu/month | 200 | 1,500 | 5,000 | GA4 |
| Pricing page views/month | 40 | 300 | 1,000 | GA4 |
| Demo booking form submissions | 5 | 40 | 120 | GA4 + DemoBookings table |
| Demo bookings to call conversion rate | 60% | 60% | 60% | Manual tracking |
| Free trial signups/month | 5 | 50 | 150 | Internal app |
| Trial-to-paid conversion rate | 20% | 30% | 35% | Stripe + internal |

### Activation Metrics (Critical for Early Stage)

| Metric | Definition | Target | Tool |
|---|---|---|---|
| Activation rate | % of signups who publish their first live menu | >50% by Day 7 | Onboarding sessions |
| Time to first menu | Hours from signup to first menu published | <4 hours (target: <2) | App analytics |
| Time to first QR code | Hours from signup to first QR code generated | <24 hours | App analytics |
| Time to first order | Days from signup to first real guest order | <7 days | Ordr model |
| Onboarding call attended rate | % of new restaurants who attend onboarding call | >80% in Phase 1 | Calendar/manual |

### Engagement and Retention

| Metric | Definition | Target | Tool |
|---|---|---|---|
| Weekly active restaurants | % of paid restaurants with at least 1 order in the last 7 days | >60% | Ordrs table |
| Monthly churn rate | % of paying restaurants who cancel in a given month | <5% | Stripe |
| Net Revenue Retention (NRR) | MRR retained + expansion / starting MRR | >100% by Month 6 | Stripe + manual |
| Plan upgrade rate | % of Starter customers who upgrade to Pro within 90 days | >15% | Stripe |
| NPS score | Net Promoter Score from restaurants | >40 by Month 6 | Survey (Day 14 + Day 90) |

### Sales Efficiency

| Metric | Definition | Target | Tool |
|---|---|---|---|
| CAC (blended) | Total acquisition cost / new customers | <EUR 200 | Marketing spend / new customers |
| CAC payback period | Months to recover CAC | <6 months | CAC / ARPU |
| LTV:CAC ratio | LTV / CAC | >3:1 by Month 6 | Calculated |
| Demo-to-paid conversion | % of demo calls that result in a paid subscription | >25% | CRM |
| Outbound email open rate | % of cold outreach emails opened | >30% | Email tool |
| Outbound reply rate | % of cold outreach emails that get a reply | >5% | Email tool |

---

## 4. Channel Attribution Framework

All marketing activities should be tagged with UTM parameters so you can attribute signups and revenue to specific channels.

### UTM Framework

| Parameter | Values | Example |
|---|---|---|
| utm_source | linkedin, google, producthunt, referral, email, facebook, direct | utm_source=linkedin |
| utm_medium | organic, cpc, post, dm, newsletter, press, event | utm_medium=organic |
| utm_campaign | launch-q2-2026, outbound-april, multilingual-feature, partnership-square | utm_campaign=launch-q2-2026 |
| utm_content | founder-post, demo-video, case-study-dublin | utm_content=case-study-dublin |

### Channel Attribution Rules
- First-touch attribution for acquisition (which channel first brought the restaurant to the site)
- Last-touch attribution for conversion (which channel triggered the trial/demo booking)
- Document both in GA4 using the default attribution model + cross-channel comparison

### Weekly Channel Review
Every Monday, review:
- Sessions by channel (GA4)
- Demo bookings by channel (DemoBookings + UTM)
- Trial signups by channel
- New paying restaurants by attributed channel

---

## 5. Monthly Review Template

Use this structure for your monthly marketing/growth review.

```
## [Month] Review — mellow.menu

### MRR
- Opening MRR: EUR X
- New MRR: EUR X (from N new restaurants)
- Churned MRR: EUR X (from N churned restaurants)
- Expansion MRR: EUR X (upgrades)
- Closing MRR: EUR X
- MoM growth: X%

### Restaurant Count
- New restaurants (trial start): N
- New restaurants (paid): N
- Churned restaurants: N
- Total active paying: N

### Funnel
- Visitors: N
- Demo bookings: N
- Trials started: N
- Trial-to-paid conversion: X%
- Activation rate (menu live Day 7): X%

### Top Channel Performance
| Channel | Leads | Signups | Revenue Attributed |
|---|---|---|---|
| Outbound | | | |
| LinkedIn | | | |
| Referral | | | |
| Organic search | | | |
| Other | | | |

### Top Insights
1. [What worked]
2. [What didn't work]
3. [What to change next month]

### NPS / Testimonials
- New testimonials: N
- Current NPS: X
```

---

## 6. Warning Signs (When to Investigate Immediately)

| Signal | Threshold | Likely Cause | Immediate Action |
|---|---|---|---|
| Monthly churn > 8% | Any month | Onboarding failure, product bug, pricing mismatch | Call every churned customer within 48 hours |
| Trial activation rate < 30% | Any week | Onboarding friction, signup too complex | Review last 5 signups; watch session recordings |
| Demo-to-paid < 15% | Any month | Wrong ICP, wrong messaging, wrong pricing | Review 5 lost deals; adjust pitch |
| NPS below 20 | First survey | Unmet expectations, product bug, support failure | Review all sub-7 scores; call each detractor |
| MoM growth < 5% from Month 4 | Two consecutive months | Channel exhaustion, churn offsetting growth | Diversify acquisition channels; review pricing |

---

## 7. Fundraising Readiness Metrics

If you plan to raise funding in 2027, the metrics that matter most to early-stage B2B SaaS investors:

| Metric | Target for Seed Round | Why It Matters |
|---|---|---|
| MRR | EUR 10k+ | Proof of willingness to pay |
| MoM growth | >10% | Momentum |
| LTV:CAC | >3:1 | Unit economics |
| Net Revenue Retention | >100% | Customers expand, not just retain |
| Churn | <5% monthly | Retention = product-market fit |
| Restaurant count | 50+ | Breadth, not just depth |
| NPS | >40 | Satisfaction and advocacy |

---

*Priority: High | Owner: Founder | Effort: Set up in Week 1; review weekly thereafter*

# Smart Menu - Product Requirements Document
# Part 4: Subscription Plans & Business Model

**Version:** 1.0  
**Last Updated:** October 26, 2025

---

## Table of Contents

1. [Subscription Tiers](#subscription-tiers)
2. [Feature Matrix](#feature-matrix)
3. [Pricing Strategy](#pricing-strategy)
4. [Plan Limitations](#plan-limitations)
5. [Upgrade/Downgrade Flow](#upgradedowngrade-flow)
6. [Payment Processing](#payment-processing)

---

## Subscription Tiers

### Overview

Smart Menu offers four subscription tiers designed to accommodate restaurants of all sizes, from small cafes to large enterprise chains. Each tier provides progressively more features and higher limits.

### Plan Structure

```
Starter → Pro → Business → Enterprise
  $29      $79     $199      Custom
```

---

## 1. Starter Plan

**Target Audience:** Small cafes, food trucks, single-location restaurants

**Monthly Price:** $29/month  
**Annual Price:** $290/year (save $58)

### Core Limits
- **Locations:** 1 restaurant
- **Menus per Location:** 3 menus
- **Items per Menu:** 50 items
- **Languages:** 2 languages
- **Tables:** 20 tables

### Features Included
✅ Digital menu management  
✅ QR code ordering  
✅ Basic inventory tracking  
✅ Staff ordering interface  
✅ Dietary filters (vegetarian, vegan, gluten-free)  
✅ Basic allergen management  
✅ Real-time order management  
✅ Kitchen dashboard  
✅ Basic analytics (30 days)  
✅ Email support  

### Features NOT Included
❌ Customer ordering (staff only)  
❌ AI menu image generation  
❌ OCR menu import  
❌ Advanced analytics  
❌ Multi-language support (>2)  
❌ API access  
❌ Priority support  
❌ Custom branding  

### Use Cases
- Small cafe with breakfast and lunch menus
- Food truck with limited menu
- Bar with drinks menu
- Small restaurant testing digital menus

---

## 2. Pro Plan (Most Popular)

**Target Audience:** Growing restaurants, multi-menu venues

**Monthly Price:** $79/month  
**Annual Price:** $790/year (save $158)

### Core Limits
- **Locations:** 3 restaurants
- **Menus per Location:** 5 menus
- **Items per Menu:** 100 items
- **Languages:** 5 languages
- **Tables:** 50 tables per location

### Features Included
✅ All Starter features, plus:  
✅ **Customer ordering** (not just staff)  
✅ **AI menu image generation** (50 images/month)  
✅ **OCR menu import** (3 imports/month)  
✅ **Advanced analytics** (90 days, export to CSV)  
✅ **Multi-language support** (up to 5 languages)  
✅ **Inventory management** with auto-restock alerts  
✅ **Table management** with seating plans  
✅ **Order history** (90 days)  
✅ **Email & chat support**  

### Features NOT Included
❌ Unlimited locations  
❌ API access  
❌ Custom integrations  
❌ Dedicated account manager  
❌ White-label branding  
❌ Advanced reporting  

### Use Cases
- Restaurant with multiple menus (lunch, dinner, drinks, dessert)
- Small restaurant chain (2-3 locations)
- Restaurant with international customers
- Venue with seasonal menu changes

---

## 3. Business Plan

**Target Audience:** Multi-location restaurants, small chains

**Monthly Price:** $199/month  
**Annual Price:** $1,990/year (save $398)

### Core Limits
- **Locations:** 10 restaurants
- **Menus per Location:** 10 menus
- **Items per Menu:** 200 items
- **Languages:** 10 languages
- **Tables:** 100 tables per location

### Features Included
✅ All Pro features, plus:  
✅ **Unlimited AI image generation**  
✅ **Unlimited OCR imports**  
✅ **API access** (REST API with authentication)  
✅ **Advanced analytics** (1 year, export to PDF/Excel)  
✅ **Custom reporting** with scheduled exports  
✅ **Multi-location management** dashboard  
✅ **Staff management** with roles and permissions  
✅ **Inventory sync** across locations  
✅ **Payment integration** (Stripe)  
✅ **Priority email & phone support**  
✅ **Onboarding assistance**  

### Features NOT Included
❌ Unlimited locations  
❌ Dedicated account manager  
❌ White-label branding  
❌ Custom integrations  
❌ SLA guarantee  

### Use Cases
- Restaurant chain (5-10 locations)
- Franchise with standardized menus
- Hotel with multiple dining venues
- Large venue with extensive menu offerings

---

## 4. Enterprise Plan

**Target Audience:** Large restaurant chains, franchises, enterprise customers

**Monthly Price:** Custom (Contact Sales)  
**Typical Range:** $500-$2,000+/month

### Core Limits
- **Locations:** Unlimited
- **Menus per Location:** Unlimited
- **Items per Menu:** Unlimited
- **Languages:** Unlimited
- **Tables:** Unlimited

### Features Included
✅ All Business features, plus:  
✅ **Unlimited everything** (locations, menus, items, languages)  
✅ **Dedicated account manager**  
✅ **Custom integrations** (POS, inventory systems, etc.)  
✅ **White-label branding** (custom domain, logo, colors)  
✅ **Advanced API access** with webhooks  
✅ **Custom analytics** and reporting  
✅ **Data insights & AI recommendations**  
✅ **SLA guarantee** (99.9% uptime)  
✅ **24/7 priority support** (phone, email, chat)  
✅ **Custom training** for staff  
✅ **Migration assistance** from existing systems  
✅ **Quarterly business reviews**  

### Use Cases
- Large restaurant chain (50+ locations)
- International franchise
- Hotel chain with multiple properties
- Corporate dining services
- Stadium/arena food services

---

## Feature Matrix

### Complete Feature Comparison

| Feature | Starter | Pro | Business | Enterprise |
|---------|---------|-----|----------|------------|
| **Locations** | 1 | 3 | 10 | Unlimited |
| **Menus per Location** | 3 | 5 | 10 | Unlimited |
| **Items per Menu** | 50 | 100 | 200 | Unlimited |
| **Languages** | 2 | 5 | 10 | Unlimited |
| **Tables** | 20 | 50/loc | 100/loc | Unlimited |
| **Digital Menu Management** | ✅ | ✅ | ✅ | ✅ |
| **QR Code Ordering** | ✅ | ✅ | ✅ | ✅ |
| **Staff Ordering** | ✅ | ✅ | ✅ | ✅ |
| **Customer Ordering** | ❌ | ✅ | ✅ | ✅ |
| **Multi-Language Support** | 2 | 5 | 10 | Unlimited |
| **Dietary Filters** | ✅ | ✅ | ✅ | ✅ |
| **Allergen Management** | Basic | ✅ | ✅ | ✅ |
| **Inventory Tracking** | Basic | ✅ | ✅ | ✅ |
| **Real-Time Kitchen Dashboard** | ✅ | ✅ | ✅ | ✅ |
| **Order Management** | ✅ | ✅ | ✅ | ✅ |
| **Table Management** | ❌ | ✅ | ✅ | ✅ |
| **AI Image Generation** | ❌ | 50/mo | Unlimited | Unlimited |
| **OCR Menu Import** | ❌ | 3/mo | Unlimited | Unlimited |
| **Analytics History** | 30 days | 90 days | 1 year | Unlimited |
| **Analytics Export** | ❌ | CSV | CSV/PDF/Excel | Custom |
| **Custom Reporting** | ❌ | ❌ | ✅ | ✅ |
| **API Access** | ❌ | ❌ | ✅ | ✅ |
| **Payment Integration** | ❌ | ❌ | ✅ | ✅ |
| **Multi-Location Dashboard** | ❌ | ❌ | ✅ | ✅ |
| **Staff Management** | ❌ | ❌ | ✅ | ✅ |
| **White-Label Branding** | ❌ | ❌ | ❌ | ✅ |
| **Custom Integrations** | ❌ | ❌ | ❌ | ✅ |
| **Dedicated Account Manager** | ❌ | ❌ | ❌ | ✅ |
| **SLA Guarantee** | ❌ | ❌ | ❌ | 99.9% |
| **Support** | Email | Email/Chat | Email/Chat/Phone | 24/7 Priority |

---

## Pricing Strategy

### Pricing Philosophy

**Value-Based Pricing:** Pricing is based on the value delivered to restaurants, not just feature count. Higher tiers provide features that directly impact revenue (customer ordering, analytics, multi-location management).

**Tiered Approach:** Clear progression from small to large businesses, with each tier targeting a specific market segment.

**Annual Discount:** 16-20% discount for annual billing to encourage long-term commitment and reduce churn.

### Pricing Rationale

**Starter ($29/month):**
- Entry-level pricing for small businesses
- Covers basic operational costs
- Encourages trial and adoption
- Limited features drive upgrades

**Pro ($79/month):**
- Sweet spot for most restaurants
- Includes revenue-generating features (customer ordering)
- AI features add significant value
- Competitive with market alternatives

**Business ($199/month):**
- Premium pricing for multi-location value
- API access and advanced features justify cost
- Target customers have higher budgets
- ROI through operational efficiency

**Enterprise (Custom):**
- Flexible pricing based on scale and needs
- Includes high-touch services (account manager, custom integrations)
- Negotiated based on number of locations and usage
- Typical range: $500-$2,000+/month

### Competitive Positioning

**vs. Traditional POS Systems:**
- Lower upfront cost (no hardware required)
- Faster deployment (5 minutes vs. weeks)
- Modern customer experience (QR codes, mobile-first)

**vs. Other Digital Menu Platforms:**
- Comprehensive feature set (ordering + analytics + inventory)
- Better pricing for small businesses
- Superior AI capabilities (OCR import, image generation)

---

## Plan Limitations

### Enforcement Strategy

**Soft Limits:**
- Warnings when approaching limits
- Grace period before enforcement
- Upgrade prompts with clear benefits

**Hard Limits:**
- Cannot exceed location/menu/item limits
- Features disabled when limit reached
- Clear messaging on why action is blocked

### Limit Tracking

**Database Implementation:**
```ruby
class Plan < ApplicationRecord
  # Limits stored as integers
  # -1 = unlimited
  # 0+ = specific limit
  
  def locations # e.g., 1, 3, 10, -1
  def menusperlocation # e.g., 3, 5, 10, -1
  def itemspermenu # e.g., 50, 100, 200, -1
  def languages # e.g., 2, 5, 10, -1
end
```

**Validation:**
```ruby
# Before creating restaurant
if user.restaurants.count >= user.plan.locations && user.plan.locations != -1
  raise "Plan limit reached. Please upgrade."
end

# Before creating menu
if restaurant.menus.count >= user.plan.menusperlocation && user.plan.menusperlocation != -1
  raise "Plan limit reached. Please upgrade."
end
```

### Limit Display

**Dashboard:**
- Usage indicators (e.g., "2 of 3 locations used")
- Progress bars showing limit consumption
- Upgrade CTA when approaching limits

**Upgrade Prompts:**
- Modal when limit reached
- Clear explanation of limit
- One-click upgrade to next tier
- Show additional features gained

---

## Upgrade/Downgrade Flow

### Upgrade Process

**User-Initiated:**
1. User clicks "Upgrade" button
2. Plan comparison displayed
3. User selects new plan
4. Payment method confirmed/updated
5. Prorated charge calculated
6. Upgrade processed immediately
7. New features unlocked

**System Actions:**
- Calculate prorated amount
- Process payment via Stripe
- Update user's plan association
- Update plan limits
- Track analytics event: `plan_upgraded`
- Send confirmation email
- Show success message

**Proration:**
```
Prorated Amount = (New Plan Price - Old Plan Price) × (Days Remaining / Days in Month)
```

### Downgrade Process

**User-Initiated:**
1. User clicks "Change Plan"
2. Selects lower tier
3. Warning displayed about feature loss
4. Confirmation required
5. Downgrade scheduled for next billing cycle

**System Actions:**
- Schedule downgrade for billing cycle end
- Send confirmation email with effective date
- Display countdown to downgrade
- Allow cancellation of scheduled downgrade
- On effective date:
  - Update user's plan
  - Disable features not in new plan
  - Archive excess data (don't delete)
  - Send confirmation email

**Feature Loss Handling:**
- If exceeds new limits, archive excess data
- Don't delete data (allow re-upgrade)
- Clear messaging about what will be disabled
- Offer to export data before downgrade

### Cancellation Process

**User-Initiated:**
1. User clicks "Cancel Subscription"
2. Exit survey displayed (optional)
3. Retention offer (optional discount)
4. Confirmation required
5. Cancellation scheduled for billing cycle end

**System Actions:**
- Schedule cancellation
- Continue service until end of billing period
- Send confirmation email
- Offer to export data
- On effective date:
  - Downgrade to free tier (if exists) or disable account
  - Archive all data
  - Send final email with data export link

---

## Payment Processing

### Payment Methods

**Supported:**
- Credit/Debit Cards (Visa, Mastercard, Amex, Discover)
- Digital Wallets (Apple Pay, Google Pay)
- ACH/Bank Transfer (Enterprise only)

**Payment Processor:** Stripe

### Billing Cycle

**Monthly:**
- Charged on same day each month
- Prorated for mid-cycle upgrades
- Automatic renewal

**Annual:**
- Charged once per year
- 16-20% discount
- Automatic renewal
- Prorated refund for downgrades

### Failed Payments

**Retry Schedule:**
- Day 1: Immediate retry
- Day 3: Second attempt
- Day 7: Third attempt
- Day 10: Final attempt

**User Communication:**
- Email notification on failure
- Dashboard banner with update payment link
- Grace period (10 days) before service suspension

**Service Suspension:**
- After 10 days of failed payment
- Account suspended (not deleted)
- Data preserved for 30 days
- Can reactivate by updating payment

### Invoicing

**Automatic:**
- Invoice generated on payment
- Sent via email
- Available in dashboard
- PDF download

**Enterprise:**
- Custom invoicing terms
- Net 30/60/90 payment terms
- Purchase orders supported
- Dedicated billing contact

---

## Business Model Summary

### Revenue Streams

1. **Subscription Revenue (Primary):**
   - Monthly/annual subscriptions
   - Predictable recurring revenue
   - Tiered pricing for different segments

2. **Add-On Services (Future):**
   - Additional AI image generation credits
   - Extra OCR imports
   - Premium support packages
   - Custom integrations

3. **Transaction Fees (Future):**
   - Small percentage on orders (optional)
   - Payment processing fees
   - Third-party delivery integration fees

### Unit Economics

**Customer Acquisition Cost (CAC):**
- Target: $100-$300 per customer
- Channels: SEO, content marketing, paid ads, partnerships

**Lifetime Value (LTV):**
- Starter: $348 (12 months × $29)
- Pro: $948 (12 months × $79)
- Business: $2,388 (12 months × $199)
- Target LTV:CAC ratio: 3:1

**Churn Rate:**
- Target: < 5% monthly churn
- Strategies: Onboarding, customer success, feature adoption

### Growth Strategy

**Land and Expand:**
- Start with Starter plan
- Upgrade as business grows
- Add locations over time
- Increase feature usage

**Market Segmentation:**
- Small businesses: Starter/Pro
- Growing chains: Pro/Business
- Enterprise: Custom solutions

---

## Next Steps

This completes the Product Requirements Document for Smart Menu. The five parts provide comprehensive coverage of:

1. **Part 1:** Executive Summary & Product Overview
2. **Part 2:** Core Features & Functional Requirements
3. **Part 3:** User Journeys & Workflows
4. **Part 4:** Subscription Plans & Business Model (this document)

For technical implementation details, refer to the codebase documentation in:
- `docs/architecture/` - System architecture
- `docs/api/` - API specifications
- `docs/development/` - Development guides

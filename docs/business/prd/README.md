# Smart Menu - Product Requirements Document

**Version:** 1.0  
**Last Updated:** October 26, 2025  
**Status:** Active  
**Document Owner:** Product Team

---

## Overview

This Product Requirements Document (PRD) provides comprehensive specifications for the Smart Menu platform - a digital menu and ordering system for restaurants. The PRD has been reverse-engineered from the current implementation to document all features, workflows, and business logic.

---

## Document Structure

The PRD is organized into four main parts:

### [Part 1: Executive Summary & Product Overview](./01-executive-summary.md)

**Contents:**
- Executive Summary
- Product Overview (Vision, Mission, Capabilities)
- Technology Stack
- Product Architecture
- User Personas (Restaurant Owner, Staff, Customer, Kitchen Manager)
- Success Metrics

**Purpose:** Provides high-level overview of the product, target market, and key stakeholders.

---

### [Part 2: Core Features & Functional Requirements](./02-core-features.md)

**Contents:**
1. User Onboarding (5-step wizard)
2. Menu Management (hierarchy, CRUD operations, localization)
3. OCR Menu Import (PDF processing, AI parsing, confirmation interface)
4. Smart Menu Deployment (QR codes, table settings)
5. Customer Ordering (smart menu interface, multi-language, dietary filters)
6. Order Management (lifecycle, calculations, audit trail)
7. Kitchen Management (dashboard, real-time updates)
8. Inventory Management (tracking, integration, dashboard)

**Purpose:** Detailed specifications for each core feature with technical requirements.

---

### [Part 3: User Journeys & Workflows](./03-user-journeys.md)

**Contents:**
1. Journey 1: Restaurant Owner Onboarding
2. Journey 2: Importing Existing Menu via OCR
3. Journey 3: Customer Ordering Experience
4. Journey 4: Kitchen Staff Managing Orders
5. Journey 5: Restaurant Owner Viewing Analytics
6. Journey 6: Managing Multi-Location Restaurant

**Purpose:** Step-by-step user flows with system actions, UI elements, and success criteria.

---

### [Part 4: Subscription Plans & Business Model](./04-subscription-plans.md)

**Contents:**
1. Subscription Tiers (Starter, Pro, Business, Enterprise)
2. Feature Matrix (complete comparison)
3. Pricing Strategy (rationale, competitive positioning)
4. Plan Limitations (enforcement, tracking, display)
5. Upgrade/Downgrade Flow (process, proration, feature loss)
6. Payment Processing (methods, billing, failed payments)

**Purpose:** Business model, pricing structure, and subscription management.

---

## Key Features Summary

### Core Capabilities

**Digital Menu Management**
- Create and organize menus with sections and items
- Multi-language support (English, Italian, extensible)
- Image management (upload or AI-generated via DALL-E)
- Real-time updates without reprinting

**QR Code Ordering**
- Unique QR codes per table
- Contactless ordering via mobile browser
- Session-based customer tracking
- No app download required

**OCR Menu Import**
- AI-powered PDF menu extraction
- Dual-strategy text extraction (text-based and image-based PDFs)
- ChatGPT integration for intelligent parsing
- Interactive confirmation and editing

**Real-Time Kitchen Management**
- Live order dashboard
- WebSocket-based updates
- Order status workflow (Opened → Ordered → Preparing → Ready → Delivered)
- Kitchen display system

**Inventory Tracking**
- Stock level monitoring per menu item
- Automatic deduction on order
- Scheduled inventory resets
- Low stock alerts

**Analytics & Reporting**
- Sales and revenue tracking
- Popular items analysis
- Customer behavior insights
- Materialized views for performance

**Payment Integration**
- Stripe integration for card payments
- Digital wallet support (Apple Pay, Google Pay)
- Bill generation and receipts
- Payment tracking

---

## Technology Stack

### Backend
- **Framework:** Ruby on Rails 7
- **Database:** PostgreSQL with materialized views
- **Caching:** IdentityCache, Redis
- **Background Jobs:** Sidekiq
- **Real-time:** Action Cable (WebSocket)
- **Authentication:** Devise with OAuth
- **Authorization:** Pundit (RBAC)

### Frontend
- **JavaScript:** ES6+ with importmap
- **CSS:** Bootstrap 5 with SCSS
- **Real-time:** Action Cable client
- **Tables:** Tabulator
- **Forms:** TomSelect

### External Services
- **AI/ML:** OpenAI ChatGPT, DALL-E
- **OCR:** Google Cloud Vision
- **Image Processing:** ImageMagick/MiniMagick
- **Payments:** Stripe
- **Analytics:** Custom analytics service

---

## User Personas

### 1. Restaurant Owner (Primary)
- **Age:** 35-55
- **Goal:** Reduce costs, improve efficiency, gain insights
- **Needs:** Easy setup, menu management, analytics, multi-location support

### 2. Restaurant Staff/Server (Secondary)
- **Age:** 20-40
- **Goal:** Take orders accurately, manage tables efficiently
- **Needs:** Intuitive interface, real-time status, mobile-friendly

### 3. Restaurant Customer (End User)
- **Age:** 18-65
- **Goal:** Browse menu easily, order in preferred language
- **Needs:** QR code access, multi-language, dietary filters, visual menu

### 4. Kitchen Manager (Secondary)
- **Age:** 30-50
- **Goal:** Receive orders clearly, track status, manage inventory
- **Needs:** Real-time dashboard, order status management, kitchen display

---

## Subscription Plans

### Starter - $29/month
- 1 location, 3 menus, 50 items/menu
- Staff ordering only
- Basic features

### Pro - $79/month (Most Popular)
- 3 locations, 5 menus, 100 items/menu
- Customer ordering
- AI features, OCR import
- Advanced analytics

### Business - $199/month
- 10 locations, 10 menus, 200 items/menu
- API access
- Multi-location management
- Priority support

### Enterprise - Custom
- Unlimited everything
- Dedicated account manager
- Custom integrations
- White-label branding
- SLA guarantee

---

## Success Metrics

### Business Metrics
- Monthly Recurring Revenue (MRR)
- Customer Lifetime Value (CLV)
- Churn Rate (target: < 5%)
- Upgrade Rate

### Product Metrics
- Daily Active Restaurants (DAR)
- Orders per restaurant per day
- QR code scans per day
- Order conversion rate

### Performance Metrics
- Smart menu load time (target: < 2 seconds)
- Order submission time (target: < 1 second)
- Kitchen notification latency (target: < 1 second)
- PDF processing time (target: < 2 minutes)

### Customer Satisfaction
- Net Promoter Score (NPS) - target: > 50
- Order accuracy rate (target: > 98%)
- Customer Satisfaction Score (CSAT) - target: > 4.5/5

---

## Implementation Status

### Current State (October 2025)

**✅ Completed Features:**
- User authentication and onboarding
- Menu management (full CRUD)
- OCR menu import with AI parsing
- Smart menu deployment with QR codes
- Customer ordering interface
- Real-time kitchen management
- Order lifecycle management
- Inventory tracking
- Analytics dashboard
- Payment integration (Stripe)
- Multi-language support
- Subscription plan management

**🚧 In Progress:**
- Enhanced analytics reporting
- Mobile app (native iOS/Android)
- Advanced API endpoints
- Third-party integrations (POS systems)

**📋 Planned:**
- Customer loyalty program
- Reservation system integration
- Advanced AI recommendations
- Predictive inventory management
- Multi-currency support
- Enhanced white-label capabilities

---

## Document Maintenance

### Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 26, 2025 | Product Team | Initial PRD creation from codebase |

### Review Schedule

- **Quarterly Review:** Update with new features and changes
- **Annual Review:** Comprehensive revision and strategic alignment
- **Ad-hoc Updates:** As major features are added or changed

### Stakeholders

- **Product Team:** Owns and maintains PRD
- **Engineering Team:** Implements features per PRD
- **Business Team:** Provides market insights and pricing strategy
- **Customer Success:** Provides user feedback and pain points

---

## Related Documentation

### Technical Documentation
- `/docs/architecture/` - System architecture and design patterns
- `/docs/api/` - API specifications and endpoints
- `/docs/development/` - Development setup and guidelines
- `/docs/testing/` - Testing strategy and coverage

### Business Documentation
- `/docs/business/marketing/` - Marketing strategy and materials
- `/docs/business/sales/` - Sales playbooks and pricing
- `/docs/business/support/` - Customer support guides

### Design Documentation
- `/docs/design/` - UI/UX specifications and design system
- `/HOMEPAGE_REDESIGN_PROPOSAL.md` - Homepage redesign specifications

---

## Contact

For questions or updates to this PRD, contact:

- **Product Team:** product@smartmenu.com
- **Engineering Lead:** engineering@smartmenu.com
- **Documentation:** docs@smartmenu.com

---

## Appendix

### Glossary

- **Smart Menu:** QR code-accessible digital menu with ordering capability
- **OCR:** Optical Character Recognition for extracting text from images/PDFs
- **Order Participant:** Customer or staff member associated with an order
- **Order Item:** Individual menu item within an order
- **Menu Section:** Category within a menu (e.g., Appetizers, Main Courses)
- **Table Setting:** Physical table in restaurant with unique QR code
- **Inventory:** Stock tracking for menu items
- **Materialized View:** Pre-computed database view for performance

### Acronyms

- **PRD:** Product Requirements Document
- **CRUD:** Create, Read, Update, Delete
- **QR:** Quick Response (code)
- **OCR:** Optical Character Recognition
- **AI:** Artificial Intelligence
- **API:** Application Programming Interface
- **RBAC:** Role-Based Access Control
- **MRR:** Monthly Recurring Revenue
- **CLV:** Customer Lifetime Value
- **NPS:** Net Promoter Score
- **CSAT:** Customer Satisfaction Score
- **DAR:** Daily Active Restaurants

---

**End of Product Requirements Document**

For detailed specifications, refer to individual parts:
- [Part 1: Executive Summary](./01-executive-summary.md)
- [Part 2: Core Features](./02-core-features.md)
- [Part 3: User Journeys](./03-user-journeys.md)
- [Part 4: Subscription Plans](./04-subscription-plans.md)

# Smart Menu - Product Requirements Document
# Part 1: Executive Summary & Product Overview

**Version:** 1.0  
**Last Updated:** October 26, 2025  
**Document Owner:** Product Team  
**Status:** Active

---

## Executive Summary

Smart Menu is a comprehensive digital menu and ordering platform designed for restaurants, cafes, and hospitality venues. The platform enables restaurants to digitize their menus, deploy QR code-based ordering systems, manage inventory, process orders in real-time, and gain insights through analytics.

### Key Value Propositions

**For Restaurants:**
- Reduce operational costs by eliminating paper menus and manual order entry
- Improve order accuracy with direct digital ordering
- Increase table turnover with faster service
- Gain data-driven insights into sales and customer preferences
- Support multiple locations with centralized management

**For Customers:**
- Contactless ordering via QR codes
- Multilingual menu support (English, Italian, extensible)
- Dietary filtering (vegetarian, vegan, gluten-free, allergen-based)
- Visual menu with high-quality images
- Real-time order status tracking
- Seamless dining experience

**For Staff:**
- Streamlined kitchen operations with real-time order dashboard
- Reduced manual entry errors
- Clear order status management
- Efficient table management
- Quick access to menu information

### Market Position

Smart Menu targets small to enterprise-level restaurants seeking to modernize their operations with:
- **Zero upfront hardware costs** - Works on existing customer devices
- **Quick deployment** - 5-minute setup process
- **Flexible pricing tiers** - Starter, Pro, Business, Enterprise plans
- **Comprehensive feature set** - From menu management to analytics
- **Scalable architecture** - Supports single location to multi-location chains

---

## Product Overview

### Vision

To become the leading digital menu and ordering platform that transforms the restaurant dining experience through technology, making it seamless for customers and profitable for restaurants.

### Mission

Empower restaurants of all sizes to digitize their operations, reduce costs, improve customer satisfaction, and make data-driven decisions through an intuitive, scalable platform.

### Core Product Capabilities

1. **Digital Menu Management**
   - Create, edit, and organize menus with sections, items, pricing, and images
   - Multi-language support with localized content
   - Real-time menu updates without reprinting
   - Image management with AI-generated options

2. **QR Code Ordering**
   - Deploy contactless ordering via unique QR codes per table
   - Session-based customer tracking
   - Real-time order submission to kitchen
   - Table-specific or general menu access

3. **OCR Menu Import**
   - AI-powered extraction of existing PDF menus
   - Dual-strategy text extraction (text-based and image-based PDFs)
   - ChatGPT integration for intelligent menu parsing
   - Interactive confirmation and editing interface

4. **Multi-Language Support**
   - Automatic language detection
   - Manual language selection
   - Restaurant-level locale configuration
   - Menu, section, and item translations

5. **Real-Time Kitchen Management**
   - Live order tracking and status updates
   - WebSocket-based real-time communication
   - Kitchen display system
   - Order status workflow (Opened → Ordered → Preparing → Ready → Delivered)

6. **Inventory Tracking**
   - Monitor stock levels per menu item
   - Automatic deduction on order
   - Scheduled inventory resets
   - Low stock alerts and auto-disable

7. **Analytics Dashboard**
   - Comprehensive insights into sales and performance
   - Popular items analysis
   - Revenue tracking
   - Customer behavior analytics
   - Materialized views for performance

8. **Payment Integration**
   - Stripe integration for card payments
   - Digital wallet support (Apple Pay, Google Pay)
   - Bill generation and receipt management
   - Payment tracking and reconciliation

---

## Technology Stack

### Backend
- **Framework:** Ruby on Rails 7
- **Database:** PostgreSQL with materialized views
- **Caching:** IdentityCache for performance optimization
- **Background Jobs:** Sidekiq for async processing
- **Real-time:** Action Cable (WebSocket) for live updates
- **Authentication:** Devise with OAuth support
- **Authorization:** Pundit for role-based access control

### Frontend
- **JavaScript:** Modern ES6+ with importmap
- **CSS:** Bootstrap 5 with custom SCSS
- **Build Tools:** esbuild for JavaScript, Sass for CSS
- **Real-time:** Action Cable JavaScript client
- **Tables:** Tabulator for interactive data tables
- **Forms:** TomSelect for enhanced dropdowns

### External Services
- **AI/ML:** OpenAI ChatGPT for menu parsing
- **OCR:** Google Cloud Vision for image text extraction
- **Image Processing:** ImageMagick/MiniMagick for PDF rendering
- **Image Generation:** DALL-E for AI-generated menu images
- **Payments:** Stripe for payment processing
- **Analytics:** Custom analytics service with event tracking

### Infrastructure
- **File Storage:** Active Storage with cloud storage support
- **Image Optimization:** WebP conversion, responsive variants
- **Caching Strategy:** Multi-level caching (IdentityCache, HTTP caching)
- **Performance:** Background job processing, materialized views
- **Security:** CSRF protection, SQL injection prevention, XSS protection

---

## Product Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Customer Interface                       │
│  (Smart Menu - QR Code Access, Mobile-First, Multilingual)  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ WebSocket (Real-time Updates)
                     │ HTTP/HTTPS (API Calls)
                     │
┌────────────────────┴────────────────────────────────────────┐
│                   Rails Application Server                   │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Controllers │  │   Services   │  │  Background  │     │
│  │              │  │              │  │     Jobs     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    Models    │  │    Policies  │  │    Channels  │     │
│  │              │  │  (Pundit)    │  │ (WebSocket)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  PostgreSQL  │ │    Redis     │ │   Sidekiq    │
│   Database   │ │   (Cache)    │ │   (Jobs)     │
└──────────────┘ └──────────────┘ └──────────────┘
        │
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│                    External Services                          │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   OpenAI     │  │ Google Cloud │  │    Stripe    │      │
│  │   ChatGPT    │  │    Vision    │  │   Payments   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### Data Flow

**Customer Ordering Flow:**
```
Customer → Scan QR Code → Smart Menu (Browser)
                              ↓
                    Create/Find Session
                              ↓
                    Browse Menu (Filtered)
                              ↓
                    Add Items to Cart
                              ↓
                    Submit Order (HTTP POST)
                              ↓
                    Order Created in DB
                              ↓
                    WebSocket Broadcast
                              ↓
            ┌─────────────────┴─────────────────┐
            ↓                                   ↓
    Kitchen Dashboard                   Customer Interface
    (Real-time Update)                  (Order Confirmation)
```

**Menu Import Flow:**
```
Restaurant Owner → Upload PDF
                       ↓
            Background Job (PdfMenuExtractionJob)
                       ↓
            Extract Text (PDF::Reader or Google Vision)
                       ↓
            Parse with ChatGPT
                       ↓
            Save to OcrMenuImport
                       ↓
            Display Confirmation Interface
                       ↓
            Owner Reviews & Edits
                       ↓
            Import to Menu (ImportToMenu Service)
                       ↓
            Menu Created/Updated
```

---

## User Personas

### 1. Restaurant Owner (Primary Persona)

**Demographics:**
- Age: 35-55
- Role: Owner/Manager of 1-5 restaurant locations
- Tech Savviness: Moderate
- Industry Experience: 5-20 years

**Pain Points:**
- High operational costs (printing menus, order errors, staff time)
- Lack of insights into sales and customer preferences
- Difficulty updating menus (seasonal items, price changes)
- Language barriers with international customers
- Inventory management challenges
- Slow table turnover

**Goals:**
- Reduce operational costs
- Improve order accuracy
- Gain data-driven insights
- Modernize restaurant operations
- Increase revenue and table turnover
- Expand to multiple locations

**Needs:**
- Easy setup and onboarding (< 5 minutes)
- Comprehensive menu management
- Real-time order tracking
- Analytics and reporting
- Multi-location support
- Affordable pricing with clear ROI

**Behaviors:**
- Checks dashboard daily for sales and orders
- Updates menu weekly or monthly
- Reviews analytics monthly for trends
- Manages staff and assigns roles
- Monitors inventory levels
- Responds to customer feedback

### 2. Restaurant Staff/Server (Secondary Persona)

**Demographics:**
- Age: 20-40
- Role: Waiter, Server, Kitchen Staff
- Tech Savviness: Basic to Moderate
- Industry Experience: 1-10 years

**Pain Points:**
- Order entry errors leading to customer complaints
- Communication gaps with kitchen
- Manual processes (writing orders, calculating bills)
- Difficulty managing multiple tables
- Language barriers with customers

**Goals:**
- Take orders quickly and accurately
- Communicate effectively with kitchen
- Manage multiple tables efficiently
- Reduce manual paperwork
- Provide excellent customer service

**Needs:**
- Intuitive order interface
- Real-time order status visibility
- Table management tools
- Quick access to menu information
- Mobile-friendly interface

**Behaviors:**
- Takes orders throughout shift
- Checks order status frequently
- Manages table assignments
- Processes payments
- Communicates with kitchen

### 3. Restaurant Customer (End User Persona)

**Demographics:**
- Age: 18-65
- Role: Diner
- Tech Savviness: Basic to Advanced
- Dining Frequency: Weekly to Monthly

**Pain Points:**
- Language barriers in foreign restaurants
- Unclear menu items and ingredients
- Slow service and long wait times
- Difficulty identifying dietary-appropriate items
- Unclear pricing

**Goals:**
- Browse menu easily on mobile device
- Understand ingredients and allergens
- Order in preferred language
- Get food quickly
- Pay conveniently

**Needs:**
- QR code menu access (no app download)
- Multi-language support
- Dietary filters (vegetarian, vegan, gluten-free)
- Clear pricing and descriptions
- Visual menu items (photos)
- Real-time order status

**Behaviors:**
- Scans QR code immediately upon sitting
- Browses menu for 2-5 minutes
- Applies dietary filters if needed
- Orders within 5-10 minutes
- Tracks order status
- Requests bill when finished

### 4. Kitchen Manager (Secondary Persona)

**Demographics:**
- Age: 30-50
- Role: Head Chef, Kitchen Manager
- Tech Savviness: Basic to Moderate
- Industry Experience: 10-25 years

**Pain Points:**
- Order confusion and miscommunication
- Timing coordination across multiple orders
- Inventory management
- Difficulty tracking order status
- Paper ticket management

**Goals:**
- Receive orders clearly and immediately
- Track order status efficiently
- Manage inventory effectively
- Coordinate kitchen workflow
- Maintain food quality and timing

**Needs:**
- Real-time order dashboard
- Order status management (preparing, ready, delivered)
- Inventory tracking
- Kitchen display system
- Clear order details (items, quantities, special instructions)

**Behaviors:**
- Monitors kitchen dashboard continuously
- Updates order status as food is prepared
- Checks inventory levels daily
- Coordinates with servers on order timing
- Manages kitchen staff workflow

---

## Success Metrics

### Business Metrics

**Revenue Metrics:**
- Monthly Recurring Revenue (MRR)
- Average Revenue Per User (ARPU)
- Customer Lifetime Value (CLV)
- Churn Rate
- Upgrade Rate (plan upgrades)

**Growth Metrics:**
- New restaurant sign-ups per month
- Activation rate (completed onboarding)
- Retention rate (90-day, 180-day)
- Referral rate
- Multi-location adoption rate

**Operational Metrics:**
- Average onboarding time (target: < 5 minutes)
- Time to first order (target: < 24 hours)
- Support ticket volume
- System uptime (target: 99.9%)
- API response time (target: < 200ms)

### Product Metrics

**Engagement Metrics:**
- Daily Active Restaurants (DAR)
- Weekly Active Restaurants (WAR)
- Orders per restaurant per day
- QR code scans per day
- Menu views per scan
- Order conversion rate (scans → orders)

**Feature Adoption:**
- OCR menu import usage rate
- Multi-language menu adoption
- Inventory tracking adoption
- Analytics dashboard usage
- Payment integration adoption

**Performance Metrics:**
- Smart menu load time (target: < 2 seconds)
- Order submission time (target: < 1 second)
- Kitchen notification latency (target: < 1 second)
- PDF processing time (target: < 2 minutes)
- Cache hit rate (target: > 80%)

### Customer Satisfaction Metrics

**Restaurant Owner Satisfaction:**
- Net Promoter Score (NPS) - target: > 50
- Customer Satisfaction Score (CSAT) - target: > 4.5/5
- Feature request volume
- Support satisfaction rating

**End Customer Satisfaction:**
- Order accuracy rate (target: > 98%)
- Average order time (target: < 5 minutes)
- Customer complaints per 1000 orders
- Return customer rate

---

## Next Steps

This PRD is organized into multiple documents:

1. **Part 1: Executive Summary & Product Overview** (this document)
2. **Part 2: Core Features & Functional Requirements** (see `02-core-features.md`)
3. **Part 3: User Journeys & Workflows** (see `03-user-journeys.md`)
4. **Part 4: Technical Specifications** (see `04-technical-specs.md`)
5. **Part 5: Subscription Plans & Pricing** (see `05-subscription-plans.md`)

Each document provides detailed specifications for implementing and maintaining the Smart Menu platform.

# AI Sommelier Marketing Landing Page

## Status
- Priority Rank: #37 (Marketing — Post-Launch)
- Category: Post-Launch
- Effort: S (engineering only — Rails static view; design and copy are the long-lead items)
- Dependencies: AI Sommelier feature publicly accessible; minimum 2–3 reference restaurants actively using it; marketing copy and design approved
- Refined: true

## Disposition

This is a marketing page brief, not a product feature spec. Engineering effort is small (one Rails view, one route, Bootstrap 5 styling). The long-lead blockers are copy, design, and proof-of-revenue from reference customers — not engineering.

**Implementation constraint:** Build this as a static Rails view inside the existing app, not a separate Next.js application. The "sophisticated aesthetic" referenced in the original brief is achievable with Bootstrap 5 custom theming and does not warrant a new frontend framework or separate deployment. The original brief's budget estimates ($8k–$12k frontend development) are not applicable to a Rails static view — this is 1–2 days of engineering work once copy and design are ready.

**No sprint work until:** The AI Sommelier feature is live for real customers AND marketing has approved copy and design assets.

## Problem Statement

Once the AI Sommelier feature has real restaurant customers and demonstrable results, mellow.menu needs a public landing page to convert inbound interest (search, paid ads, word of mouth) into demo bookings and trial sign-ups. Without this page, the feature has no discoverable public surface for acquisition.

## Success Criteria

- A `/ai-sommelier` route renders a marketing page in the existing Rails app
- Page includes: hero with CTA linking to the existing demo booking flow, feature overview, benefits, social proof (real quotes from reference restaurants), and an FAQ
- Page is indexed by search engines (no `noindex`) with correct meta tags and schema markup
- CTA links route to the existing demo/trial sign-up flow — no new form infrastructure required
- Page renders correctly on mobile (Bootstrap 5 responsive grid)

## User Stories

- As a restaurant owner searching for wine recommendation software, I want to land on a compelling page that explains the AI Sommelier feature and makes it easy to request a demo.
- As a marketing team member, I want to update the page copy without needing a developer (consider using a simple ERB content partial or a YAML locale file for copy).

## Functional Requirements

1. New route: `GET /ai-sommelier` → `MarketingController#ai_sommelier` (or extend existing `HomeController` if a marketing controller already exists)
2. Static view — no database queries, no authentication required
3. Hero section: headline, subheadline, and a "Request Demo" CTA button linking to the existing Calendly or demo-booking flow
4. Features section: 3–4 bullet benefits (copy TBD by marketing)
5. Social proof section: 2–3 testimonial quotes from reference restaurants (copy TBD; placeholder markup ready for real quotes)
6. FAQ section: 4–6 questions (copy TBD by marketing)
7. SEO: `<title>`, `<meta description>`, Open Graph tags, and `Restaurant` schema markup in the `<head>`
8. No React, no Next.js, no additional JS framework — plain ERB with Bootstrap 5

## Non-Functional Requirements

- Page must load in under 2 seconds on a 3G connection (no heavy JS bundles, no video autoplay)
- No new gems required
- Copy must be stored in `config/locales/en/marketing.en.yml` so it can be updated without code changes

## Technical Notes

- Route: `get '/ai-sommelier', to: 'marketing#ai_sommelier'` (or `home#ai_sommelier`)
- Controller: `MarketingController < ApplicationController` — `skip_before_action :authenticate_user!` if authentication is required globally
- View: `app/views/marketing/ai_sommelier.html.erb` — uses `application` layout or a dedicated `marketing` layout
- No Pundit policy needed (public page)
- No Flipper flag needed (public page — launch when copy is ready)
- No Sidekiq job needed

## Acceptance Criteria

1. `GET /ai-sommelier` returns HTTP 200 for both authenticated and unauthenticated users.
2. Page title and meta description are present and contain "AI Sommelier".
3. The "Request Demo" CTA links to the existing demo booking URL.
4. Page renders without JavaScript errors on mobile and desktop.
5. `robots.txt` allows crawling of `/ai-sommelier`.

## Out of Scope

- Interactive wine pairing demo tool (requires significant engineering — separate spec if needed)
- ROI calculator (separate spec if needed)
- Video testimonials (requires video production — marketing lead item)
- Paid advertising campaign setup (marketing, not engineering)
- A separate Next.js or premium frontend build (ruled out — Rails view is sufficient)

## Open Questions

1. Does a `MarketingController` already exist, or should this extend `HomeController`?
2. Who owns the copy and design approval gate — and what is the target date for those assets?
3. Should the page be localised at launch (e.g. Irish English vs. UK English), or English-only initially?

## Overview
Create a compelling marketing landing page showcasing mellow.menu's AI Sommelier functionality to attract wine enthusiasts and premium restaurants.

## Business Objectives
- **Lead Generation**: Capture restaurant sign-ups for AI Sommelier feature
- **Brand Awareness**: Establish mellow.menu as an innovative dining platform
- **Conversion**: Convert visitors to trial users
- **Education**: Demonstrate AI capabilities and benefits

## Target Audience

### Primary
- **Restaurant Owners**: Fine dining establishments, wine bars, steakhouses
- **Sommeliers**: Professional wine experts seeking digital tools
- **Restaurant Managers**: Focused on enhancing guest experience

### Secondary
- **Wine Enthusiasts**: Individual diners interested in wine pairing
- **Event Planners**: Corporate and private event organizers
- **Food Bloggers**: Influencers in dining and wine space

## Page Structure

### Hero Section
- **Headline**: "Transform Your Wine Program with AI Sommelier"
- **Subheadline**: "Intelligent wine pairing recommendations that delight guests and increase sales"
- **CTA**: "Request Demo" / "Start Free Trial"
- **Visual**: Animated wine pairing visualization
- **Social Proof**: "Trusted by 500+ premium restaurants"

### Problem Statement
- **Current Challenges**: 
  - Guests overwhelmed by extensive wine lists
  - Staff knowledge gaps in wine pairing
  - Missed upselling opportunities
  - Inconsistent guest experiences

### Solution Overview
- **AI Sommelier Features**:
  - Real-time wine pairing recommendations
  - Personalized suggestions based on guest preferences
  - Staff training and knowledge enhancement
  - Sales analytics and insights

### How It Works
1. **Menu Analysis**: AI analyzes your menu items and flavor profiles
2. **Wine Database**: Access to 50,000+ wines with detailed profiles
3. **Smart Pairing**: Intelligent matching algorithm considers taste, price, and availability
4. **Guest Personalization**: Learning from guest preferences and feedback

### Benefits Section

#### For Restaurants
- **Increase Sales**: 25% average increase in wine sales
- **Enhance Experience**: Memorable dining experiences
- **Staff Efficiency**: Reduce training time and increase confidence
- **Data Insights**: Understand guest preferences and trends

#### For Guests
- **Perfect Pairings**: Discover ideal wine matches
- **Personalized Service**: Tailored recommendations
- **Wine Education**: Learn about wines and pairings
- **Confidence**: Order wine with confidence

### Features Deep Dive

#### AI Intelligence
- **Flavor Profile Analysis**: Complex taste matching algorithms
- **Price Optimization**: Balance guest preferences with price points
- **Availability Integration**: Real-time inventory awareness
- **Seasonal Adjustments**: Adapt to seasonal menu changes

#### Staff Tools
- **Mobile Access**: Tablet and mobile phone compatibility
- **Quick Training**: Rapid onboarding for new staff
- **Confidence Building**: Suggested talking points and descriptions
- **Upselling Guidance**: Natural upselling opportunities

#### Analytics Dashboard
- **Sales Tracking**: Monitor wine pairing performance
- **Guest Insights**: Understand preference patterns
- **Menu Optimization**: Identify popular pairings
- **ROI Measurement**: Track revenue impact

### Social Proof
- **Testimonials**: Quotes from restaurant owners and sommeliers
- **Case Studies**: Detailed success stories with metrics
- **Client Logos**: Recognizable restaurant brands
- **Press Mentions**: Media coverage and awards

### Pricing Section
- **Tiered Plans**: Basic, Professional, Enterprise
- **Feature Comparison**: Clear plan differentiation
- **ROI Calculator**: Interactive tool to estimate returns
- **Free Trial**: 30-day risk-free trial

### Technical Integration
- **Easy Setup**: 15-minute installation process
- **POS Integration**: Compatible with major POS systems
- **Menu Import**: Automatic menu synchronization
- **Mobile Apps**: iOS and Android applications

### FAQ Section
- **Common Questions**: Address implementation concerns
- **Technical Requirements**: System compatibility
- **Support Options**: Customer service details
- **Data Security**: Information protection measures

## Technical Requirements

### Frontend Implementation
- **Framework**: React/Next.js for optimal performance
- **Animations**: Smooth scroll animations and micro-interactions
- **Responsive**: Mobile-first responsive design
- **Performance**: Optimized for fast loading

### Interactive Elements
- **Wine Pairing Demo**: Interactive demonstration
- **ROI Calculator**: Dynamic return on investment tool
- **Menu Upload**: Drag-and-drop menu analysis
- **Video Testimonials**: Embedded video content

### Analytics & Tracking
- **Conversion Tracking**: Google Analytics and Tag Manager
- **Heat Mapping**: User behavior analysis
- **A/B Testing**: Conversion optimization
- **Lead Scoring**: Qualify incoming leads

## Content Strategy

### Messaging Pillars
1. **Innovation**: Cutting-edge AI technology
2. **Results**: Measurable business impact
3. **Simplicity**: Easy implementation and use
4. **Expertise**: Wine knowledge and sophistication

### Tone of Voice
- **Sophisticated**: Reflect wine industry standards
- **Approachable**: Avoid overly technical language
- **Confident**: Demonstrate expertise and reliability
- **Results-oriented**: Focus on business outcomes

### Visual Direction
- **Elegant**: Premium, refined aesthetic
- **Wine-focused**: Wine imagery and colors
- **Professional**: Clean, modern design
- **Appetizing**: Food and wine photography

## SEO Strategy

### Target Keywords
- **Primary**: "AI sommelier", "wine pairing software", "restaurant wine recommendations"
- **Secondary**: "wine list management", "restaurant wine program", "digital sommelier"
- **Long-tail**: "how to increase wine sales", "wine pairing AI technology", "restaurant wine optimization"

### Content Optimization
- **Meta Tags**: Optimized titles and descriptions
- **Schema Markup**: Structured data for search engines
- **Internal Linking**: Connect to related content
- **Page Speed**: Optimized for search rankings

## Marketing Integration

### Paid Campaigns
- **Google Ads**: Target wine industry keywords
- **Social Media**: LinkedIn and Facebook campaigns
- **Retargeting**: Website visitor remarketing
- **Display Ads**: Industry-specific placements

### Email Marketing
- **Lead Nurturing**: Automated email sequences
- **Newsletter Content**: Wine industry insights
- **Promotional Campaigns**: Feature announcements
- **Customer Stories**: Success story highlights

### Social Media
- **LinkedIn**: Professional networking and content
- **Instagram**: Visual wine and food content
- **Facebook**: Community building and advertising
- **Twitter**: Industry news and updates

## Success Metrics

### Primary KPIs
- **Conversion Rate**: Demo requests and trial sign-ups
- **Lead Quality**: Qualified restaurant leads
- **Page Engagement**: Time on page and interactions
- **Search Rankings**: Keyword position improvements

### Secondary KPIs
- **Traffic Sources**: Channel performance
- **Mobile Performance**: Mobile conversion rates
- **Form Completion**: Contact form submissions
- **Social Sharing**: Content distribution metrics

## Implementation Timeline

### Phase 1: Foundation (Weeks 1-2)
- Wireframe design and approval
- Content creation and copywriting
- Brand guideline alignment
- Technical setup

### Phase 2: Development (Weeks 3-4)
- Frontend development
- Interactive element implementation
- Integration with marketing tools
- Testing and quality assurance

### Phase 3: Launch (Weeks 5-6)
- Final testing and optimization
- Marketing campaign setup
- Launch and monitoring
- Performance analysis

## Budget Considerations

### Development Costs
- Design and UX: $5,000-8,000
- Frontend development: $8,000-12,000
- Content creation: $3,000-5,000
- Testing and QA: $2,000-3,000

### Marketing Budget
- Paid advertising: $5,000-10,000/month
- Content promotion: $2,000-3,000/month
- Analytics tools: $500-1,000/month
- A/B testing tools: $500-1,000/month

## Conclusion

The AI Sommelier landing page will serve as a powerful tool for acquiring high-value restaurant clients and establishing mellow.menu as an innovative leader in restaurant technology. The combination of compelling messaging, interactive demonstrations, and clear value propositions will drive conversions and support business growth.

Success will be measured through lead quality, conversion rates, and the ability to effectively communicate the unique value proposition of AI-powered wine recommendations in the restaurant industry.

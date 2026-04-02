# Feature-to-Marketing Map
## mellow.menu Go-To-Market Plan — Document 05

For each major product capability, this document defines the marketing claim it enables, which buyer persona it resonates with most, campaign ideas it unlocks, and any feature gaps that would strengthen the story.

---

## Feature 1 — 40+ Language Menu Localisation (DeepL)

**Marketing Claim:**
"Your menu, automatically translated into 40+ languages. Every guest reads it in their own language — no human translator, no extra work."

**Target Persona:**
- Tier 1 ICP: Independent restaurant in tourist district or multicultural city
- "Marco the Independent Owner" — sees international guests daily but has no solution

**Top Campaign Ideas:**
1. **"Before/After" content:** Show a restaurant owner's paper menu next to the same menu in French, Spanish, and Japanese — created in 60 seconds
2. **Tourist season angle:** "Summer is coming. Are your menus ready for your international guests?" (seasonal campaign, April–May)
3. **Social proof angle:** "Our pilot restaurants saw [X]% more orders from international tables after adding multilingual menus"
4. **Language count hook:** "40 languages. What percentage of your guests can't read your current menu?" — opens a conversation
5. **Video demo:** 30-second screen recording — take a photo of a paper menu, watch it appear in French and Japanese in real time

**Feature Gaps to Flag:**
- Marketing claim is stronger if we can show a guest-side language selector screenshot in marketing materials
- A language usage analytics dashboard ("Your menu was viewed in 12 languages this month") would generate shareable social proof content

---

## Feature 2 — AI Menu Optimisation (Pricing, Bundling, Engineering)

**Marketing Claim:**
"AI analyses your menu costs and tells you exactly which items to push, which to reprice, and which to cut — so your menu earns more."

**Target Persona:**
- All Tier 1 and Tier 2 ICPs — universal pain point
- Particularly resonant with owners who manage margins tightly (small chains, cafes)

**Top Campaign Ideas:**
1. **ROI calculator:** "Enter your menu size and average cover spend — see how much extra revenue better menu engineering could generate" (landing page interactive calculator)
2. **Educational content:** "The 4-box menu engineering matrix your restaurant isn't using" (blog post / LinkedIn article — references the Stars/Plowhorses/Puzzles/Dogs framework that mellow.menu AI is based on)
3. **Specific claim:** "Restaurants using AI pricing recommendations typically identify 2–3 items that should be priced 15–20% higher" (requires data from pilot restaurants to validate)
4. **Before/After case study:** Show a restaurant's margin profile before and after acting on AI recommendations
5. **Objection content:** "Is AI pricing actually useful for a small restaurant? We tested it." (honest, non-promotional blog post)

**Feature Gaps to Flag:**
- A shareable "menu health score" metric (e.g. "Your menu is 73% optimised — here's how to improve it") would be a powerful marketing hook and product virality driver
- An email digest sent to restaurants weekly with their top 3 AI recommendations would drive re-engagement and create content for testimonials

---

## Feature 3 — QR Code Table Ordering

**Marketing Claim:**
"Guests scan, order, and pay — without flagging down a waiter. Your staff focus on service, not order-taking."

**Target Persona:**
- Fast casual and casual dining (Tier 1 ICP)
- Multi-location operators (Tier 2 ICP) — standardises the ordering experience

**Top Campaign Ideas:**
1. **Staff efficiency angle:** "One waiter can serve more tables when they're not taking orders — here's the maths" (LinkedIn post with a real numbers example)
2. **Order accuracy angle:** "Digital ordering reduces errors by eliminating the 'the kitchen heard X but the table said Y' problem"
3. **Table turn angle:** "Tables that order digitally turn 12% faster on average" (source this from industry data; validate with pilot restaurants)
4. **Demo CTA:** The QR code IS the demo. Every sales call ends with: "Scan this code and order something — it takes 30 seconds. That's what your guests experience."
5. **Physical marketing collateral:** Tent cards and table stickers with "Order here" QR codes — every table becomes a mellow.menu ad

**Product-Led Growth (PLG) Opportunity:**
"Powered by mellow.menu" attribution on public menu pages creates brand exposure at every table — every guest who scans becomes a potential future customer (restaurant owner, or tells their restaurant-owner friends). This is the core viral loop.

**Feature Gaps to Flag:**
- "Powered by mellow.menu" branding on public menu pages must be implemented consistently with a link back to the marketing site (see 06_tech_roadmap_inputs.md)
- A way for restaurant owners to customise the branding colour of their QR landing page (theming) would increase perceived quality

---

## Feature 4 — Online Ordering with Bill-Splitting (Ordrparticipants)

**Marketing Claim:**
"Guests split the bill their way — by item, equally, or any combination — without asking for 6 separate receipts."

**Target Persona:**
- Casual dining targeting groups and social occasions
- Young urban diners who expect modern payment experiences

**Top Campaign Ideas:**
1. **Guest experience angle:** Target marketing to young restaurant-goers via Instagram and TikTok (Phase 3): "Split the bill without the awkward negotiation"
2. **Owner benefit reframe:** "Bill splitting at the table means faster payment and fewer disputes. Your staff close the table and move on."
3. **Competitor differentiation:** Most competitors do not offer party-style bill splitting natively — this is a genuine differentiator worth highlighting in comparison content
4. **Use case video:** Short video of 4 friends scanning a QR code, each selecting their items, paying individually on their own phone

**Feature Gaps to Flag:**
- "Split equally" vs. "split by item" are both valuable marketing claims — confirm both are live in the current Ordrparticipants implementation
- A receipt delivery feature (send receipt to email) would strengthen the guest experience story

---

## Feature 5 — OCR Menu Import (Google Cloud Vision)

**Marketing Claim:**
"Import your existing menu by taking a photo. We read it, structure it, and build your digital menu automatically. Setup in 30 minutes."

**Target Persona:**
- "Marco the Independent Owner" — tech-suspicious, doesn't want to type out 80 menu items
- Tier 1 ICP broadly — reduces the activation barrier dramatically

**Top Campaign Ideas:**
1. **The "30-minute setup" guarantee:** This is the primary onboarding claim. Use it on the homepage hero, in all outbound emails, and in every sales conversation.
2. **Demo video:** The most compelling product demo is filming the OCR import live — take a photo of a real menu (paper or PDF), watch it appear as a structured digital menu in under 2 minutes
3. **Objection killer:** "I don't want to type all my menu items in." "You don't have to — just take a photo."
4. **Speed comparison:** "Most restaurants are live in 30 minutes. The longest we've seen is 45 minutes."
5. **Before/After content:** Photo of a paper menu → screenshot of the live digital menu with multilingual support

**Feature Gaps to Flag:**
- OCR accuracy is a marketing risk if output quality is inconsistent — ensure the onboarding flow includes a review/edit step before the menu goes live
- A "demo import" that lets prospects import a sample menu on the marketing site (without signing up) would be a powerful conversion tool — flag as a marketing-driven technical requirement

---

## Feature 6 — AI Image Generation for Menu Items (DALL-E)

**Marketing Claim:**
"No food photographer? No problem. mellow.menu generates professional-quality food images for every menu item using AI."

**Target Persona:**
- Independent restaurants without a marketing budget
- Cafes and fast casual (menus with high item counts that would be expensive to photograph)

**Top Campaign Ideas:**
1. **Visual comparison:** Side-by-side: a restaurant's current menu (text-only) vs. the same menu with AI-generated images on each item
2. **Cost savings claim:** "A professional food photography session costs EUR 500–1,500 and takes half a day. mellow.menu generates images for your entire menu in minutes."
3. **Appetite psychology:** "Menus with images increase average order value by 20–30% — even digital images outperform text-only" (widely cited restaurant industry stat)
4. **Demo video:** Show the AI image generation flow in real time — type a dish name, press generate, watch the image appear

**Feature Gaps to Flag:**
- AI image quality for food is improving but still variable — ensure there is a regenerate/edit option before the image goes live
- The ability to upload real photos alongside AI images (mixed menu) would strengthen the offering for restaurants that have some photography
- A gallery of sample AI-generated food images on the marketing site would demonstrate the quality before signup

---

## Feature 7 — Multi-Payment Provider Support (Stripe + Square)

**Marketing Claim:**
"Already on Square or Stripe? mellow.menu works with your existing payment setup. No new payment contract, no new hardware."

**Target Persona:**
- Any restaurant currently using Square or Stripe
- Tier 1 ICP who is cautious about switching payment systems

**Top Campaign Ideas:**
1. **Integration badge:** Display "Works with Square" and "Works with Stripe" logos prominently on the pricing page and homepage
2. **Objection removal:** This claim eliminates the most common adoption objection ("do I have to change my payment system?") — use it in every sales conversation
3. **Partnership content:** Co-marketing opportunity with Square (Square is known to actively promote ISV partners) — blog posts, joint webinars

**Feature Gaps to Flag:**
- Square App Marketplace listing would drive discovery for all existing Square merchant restaurants — priority partnership action
- Stripe Partners listing would do the same for Stripe users

---

## Feature 8 — Real-Time Order and Kitchen Management

**Marketing Claim:**
"Orders flow instantly from the table to the kitchen. No paper tickets. No shouting. No lost orders."

**Target Persona:**
- Casual dining and fast casual where kitchen efficiency is a pain point
- Tier 2 multi-location operators who need standardised kitchen workflows

**Top Campaign Ideas:**
1. **Operations efficiency angle:** "Your kitchen knows what's coming before the waiter walks through the door"
2. **Error reduction angle:** "Digital orders mean no handwriting misreads, no forgotten modifications"
3. **Demo for kitchen managers:** Show the kitchen ticket screen updating in real time as a table orders — live demo is more powerful than any description

**Feature Gaps to Flag:**
- Kitchen display system (KDS) hardware integration would significantly strengthen this marketing claim for larger operations — flag as future roadmap item
- A mobile app for the kitchen (or kitchen staff) would be a strong differentiator

---

## Feature 9 — Profit Margin Tracking and Analytics

**Marketing Claim:**
"Know your actual profit margin on every dish. See which items are Stars, which are draining you, and what to do about it."

**Target Persona:**
- Business-minded owners ("I want to run a profitable restaurant, not just a busy one")
- Tier 2 multi-location operators who need reporting

**Top Campaign Ideas:**
1. **Pain point hook:** "Most restaurant owners know their best-selling dish. Almost none know their most *profitable* dish. Do you?"
2. **Dashboard screenshot:** Show a clean analytics view with items colour-coded by margin — Stars vs. underperformers
3. **Thought leadership content:** "Restaurant profit margins are at 3–5% industry-wide. Here's the one thing most owners haven't tried." (links to menu engineering content)
4. **ROI framing:** "Restaurants that acted on their margin data within 30 days improved gross profit by an average of X%" (requires pilot data to validate)

**Feature Gaps to Flag:**
- A weekly email digest with top 3 insights from the analytics dashboard would drive re-engagement and create natural social proof content
- Export to PDF for sharing with accountants or business partners would be a valued feature

---

## Feature 10 — Menu Versioning and A/B Experiments

**Marketing Claim:**
"Test two versions of your menu simultaneously. See which prices, descriptions, or item placements drive more orders."

**Target Persona:**
- Data-driven operators (Tier 2 ICP, small chains)
- Restaurants with seasonal or frequently changing menus

**Top Campaign Ideas:**
1. **Advanced feature positioning:** Market this as a Pro/Business tier differentiator — not for everyone, but powerful for the right customer
2. **Case study angle:** "How one restaurant increased their average order value by EUR 3.50 by testing two versions of their menu" — a/b test result story

**Feature Gaps to Flag:**
- This feature may not be widely known — ensure it is clearly visible on the pricing/features page as a plan differentiator
- Statistical significance guidance for small restaurants (e.g. "you need at least 200 covers to get reliable results") would add credibility

---

## Feature 11 — OCR / Menu Source Monitoring

*Internal admin feature — not marketed externally as a customer feature*

---

## Feature 12 — Staff and Employee Management

**Marketing Claim:**
"Manage staff roles and permissions across all your locations from one dashboard."

**Target Persona:**
- Tier 2 multi-location operators
- Restaurants with high staff turnover (fast casual, casual dining)

**Top Campaign Ideas:**
1. Present as part of the "Business" tier value proposition — not a primary acquisition driver, but a retention feature once customers are using the platform
2. "Your staff can take orders, close tables, and manage the floor from their phone — no dedicated terminal needed"

---

## Summary: Marketing Claim Priority Matrix

| Feature | Hook Strength | ICP Breadth | Ease of Demo | Priority for Marketing |
|---|---|---|---|---|
| Multilingual localisation (40+ languages) | Very High | High | High | #1 |
| OCR import (30-minute setup) | Very High | High | Very High | #2 |
| AI pricing / margin analytics | High | High | Medium | #3 |
| QR ordering + PLG loop | High | High | Very High | #4 |
| AI food image generation | High | Medium | Very High | #5 |
| Bill splitting | Medium | Medium | High | #6 |
| Stripe + Square dual payments | Medium (objection removal) | High | Low | #7 |
| Real-time kitchen management | Medium | Medium | High | #8 |
| Menu A/B experiments | Medium | Low | Low | #9 |

---

*Priority: High | Owner: Founder | Effort: This is a reference document — update when new features ship*

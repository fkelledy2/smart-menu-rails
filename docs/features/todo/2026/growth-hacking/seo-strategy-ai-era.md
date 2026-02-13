# SEO Strategy for mellow.menu in the AI Era — Technical Specification

## 📋 Feature Overview

**Feature Name**: SEO & Answer Engine Optimization (AEO) Strategy

**Priority**: High

**Category**: Growth Hacking / SEO / AI Discovery / Infrastructure

**Estimated Effort**: Large (ongoing — 4-week initial sprint, then continuous iteration)

**Target Release**: 2026

## 🥅 Overall Goals

1. Position mellow.menu as the **canonical structured source for restaurant menus** that AI systems trust and cite.
2. Shift from traditional SEO ("rank #1 on Google") to **AEO** (Answer Engine Optimization) — be the answer inside AI assistants, voice search, and vertical discovery platforms.
3. Build a scalable, automated content and structured-data engine powered by the existing Rails + Sidekiq stack.
4. Create a defensible data moat: if AI models need structured menus, allergens, pricing, and pairings — mellow.menu is the infrastructure layer.

## 🔗 Related Specifications / References

- Claim Your Restaurant growth engine: `../done/city-menu-crawler-claim-your-restaurant.md`
- Admin pattern (separate Admin namespace, super admin gating): `../../features/super-admin-impersonation-act-as-user.md`

---

## 1️⃣ The Shift: SEO → AEO (Answer Engine Optimization)

Search behaviour is fragmenting across:

- **Google** (still huge, but declining as sole entry point)
- **AI assistants** (ChatGPT, Gemini, Claude, Grok, Perplexity)
- **Voice search** (Siri, Alexa, Google Assistant)
- **In-app AI** inside maps / booking platforms
- **Vertical discovery** (Instagram, TikTok, Apple Maps, etc.)

The goal is no longer *"get traffic"*. The goal is:

> **Become the canonical structured source for restaurant menus.**

---

## 2️⃣ Mellow's Strategic Advantage

mellow.menu is not just content. It is:

- **Structured menu data** (sections, items, prices, sizes)
- **Multilingual content** (10+ locales)
- **AI-enhanced dish descriptions** (LLM-generated, grounded in real data)
- **Allergen tagging** (EU-14, FDA Top 8)
- **Real-time updates** (menus change, data stays current)
- **Geo-location** tied to restaurants (lat/lng, city, country)

This is exactly what AI models need. The SEO strategy should therefore be:

> **Build the world's best structured restaurant menu dataset. Not just pages.**

---

## 3️⃣ The 4-Pillar SEO Strategy

### 🧱 Pillar 1 — Structured Data Domination

Every restaurant page must expose full Schema.org markup:

- `Restaurant`
- `Menu`
- `MenuItem`
- `Offer` (pricing)
- `AggregateRating`
- `GeoCoordinates`
- `OpeningHours`
- `NutritionInformation` / allergen data (where available)

**This is not optional. It is mandatory.**

If done correctly:

- Google can parse it
- AI crawlers can parse it
- LLM training pipelines can ingest it
- Perplexity, ChatGPT, and others can cite it

**Outcome**: mellow.menu becomes a trusted structured source.

#### Implementation Notes

- Render JSON-LD in `<head>` of every public smartmenu page
- Use existing `Restaurant`, `Menu`, `Menuitem`, `Menusection` models as data source
- Helper or presenter class: `SchemaOrgSerializer` to generate JSON-LD from ActiveRecord
- Include on: `/smartmenus/:slug`, geo-listing pages, guide pages

---

### 🗺 Pillar 2 — Location SEO at Scale

Automatically generate geo-structured listing pages:

```
/explore/ireland/dublin/italian-restaurants
/explore/italy/florence/best-pasta
/explore/hungary/budapest/vegan-restaurants
```

The database already geo-structures restaurants. Use it.

Each page should have:

- **Dynamic listing** from DB queries (city + category/tag filters)
- **Full structured data** (Schema.org `ItemList` + `Restaurant`)
- **Internal linking** between restaurants, cities, and categories
- **Multilingual support** (leverage existing `Restaurantlocale` system)
- **Canonical URLs** and hreflang tags

#### Implementation Notes

- New `ExploreController` with routes: `/explore/:country/:city(/:category)`
- Background job (`GeoPageGeneratorJob`) to discover and cache valid city/category combos from restaurant data
- Sidekiq scheduled job to refresh listings nightly
- Server-side rendered (Turbo compatible, no JS-only rendering)
- Pre-rendered meta tags (`title`, `description`, `og:*`, `twitter:*`)

---

### 🤖 Pillar 3 — AI-Optimized Content (Controlled)

**Not** fluffy AI blog spam. Grounded, structured content tied to real data:

- "Best gluten-free dishes in Dublin"
- "Top whiskey pairings in Cork"
- "Best sommelier-recommended wines in Florence"
- "Vegan-friendly restaurants near Trinity College"

This content must:

- Be **grounded in real restaurants** on the platform
- **Link internally** to menu items and restaurant pages
- Be **regenerated when menus update** (stale content is penalised)
- Include **FAQ structured data** (`FAQPage` schema)

#### Implementation Notes

- New model: `LocalGuide` (city, category, content, published_at, regenerated_at)
- `LocalGuideGeneratorJob` — uses OpenAI (already in stack) to generate/regenerate guides from real DB entities
- Tie every claim in the guide to a real `Restaurant` / `Menuitem` record
- Regeneration trigger: when underlying restaurant menus change (via `after_commit` or nightly batch)
- Start with 1 city (Dublin), expand based on restaurant density

---

### 📍 Pillar 4 — "Claim Your Restaurant" Growth Loop (Already Implemented)

The crawler + claim flow is already built and creates:

- SEO footprint (indexed unclaimed restaurant pages)
- Inventory (structured menu data at scale)
- Inbound business leads (claim CTA on every unclaimed page)

**This is a flywheel**: more restaurants → more pages → more SEO → more claims → more restaurants.

See: `../done/city-menu-crawler-claim-your-restaurant.md`

---

## 4️⃣ Optimizing for AI Assistants Specifically

AI assistants answer questions like:

- *"Where can I get good vegetarian food in Dublin?"*
- *"Show me a restaurant in Florence with good Chianti pairings."*
- *"What are the allergen-free options at [restaurant name]?"*

To win here, content must be:

- ✅ **Fact-based** (grounded in real menu data)
- ✅ **Updated** (stale data gets deprioritised)
- ✅ **Structured** (Schema.org, clean HTML, semantic markup)
- ✅ **Cited by other sites** (backlinks from authoritative sources)

### 🔥 Bonus: Open Menu Data API

Create a **read-only, rate-limited public API** for menu data.

If developers and researchers use it → mellow.menu becomes **infrastructure**, not just a SaaS.

#### Implementation Notes

- Read-only endpoints: `/api/v2/restaurants/:id/menu`, `/api/v2/explore/:city`
- Rate-limited (100 req/hour unauthenticated, higher for API keys)
- Returns JSON-LD compatible structured data
- Attribution required: "Data by mellow.menu"
- This drives backlinks and citations organically

---

## 5️⃣ Technical SEO Stack (Rails 7 + Heroku)

### Requirements

| Requirement | Status | Notes |
|---|---|---|
| Server-side rendered pages | ✅ Turbo | No JS-only rendering for SEO pages |
| Pre-rendered meta tags | 🔲 TODO | `title`, `description`, `og:*`, `twitter:*` on all public pages |
| XML sitemap auto-generated | 🔲 TODO | Updated nightly via Sidekiq |
| Robots.txt configured | ✅ Exists | Review for AI crawler directives |
| Fast TTFB | ⚠️ Review | Heroku dyno sizing, CDN in front |
| CDN | 🔲 TODO | Cloudflare strongly recommended |
| Schema.org JSON-LD | 🔲 TODO | On all public restaurant/menu pages |

### Sidekiq Jobs Needed

- **`SitemapGeneratorJob`** — Rebuild XML sitemap nightly, ping search engines on update
- **`GeoPageGeneratorJob`** — Discover and cache valid city/category combinations
- **`LocalGuideGeneratorJob`** — Generate/regenerate AI-assisted local guides
- **`SchemaOrgValidatorJob`** — Periodic validation of structured data output (optional)

### Robots.txt Considerations

```
# Allow AI crawlers explicitly
User-agent: GPTBot
Allow: /smartmenus/
Allow: /explore/

User-agent: Google-Extended
Allow: /

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /madmin/
Sitemap: https://mellow.menu/sitemap.xml
```

---

## 6️⃣ How AI Search Actually Finds You

LLMs don't crawl live. They train on:

- High-authority pages
- Structured markup
- Popular referenced sites
- Cited material

**Backlink strategy** — seek links from:

- Food bloggers and reviewers
- Local tourism sites and city directories
- Hospitality industry publications
- Restaurant association websites
- University/college "eating out" guides

This matters far more than keyword stuffing.

---

## 7️⃣ What NOT To Do

- ❌ Blog spam (mass-generated thin articles)
- ❌ 10,000 AI articles about "best pizza"
- ❌ Thin pages with no real data behind them
- ❌ Duplicate menu content across multiple URLs
- ❌ Keyword stuffing
- ❌ JS-only rendered SEO-critical content

All of these are penalised or ignored in 2026.

---

## 8️⃣ The Long-Term Vision

> **mellow.menu becomes the canonical structured layer of the global restaurant ecosystem.**

Not just a SaaS. A **data layer**.

If AI models need structured menus, allergens, pricing, wine pairings:

→ mellow.menu is the infrastructure.

**That's an AI-era moat.**

---

## 9️⃣ Implementation Roadmap

### Phase 1 — Foundation (Week 1–2)

- [ ] Implement full Schema.org JSON-LD on all public smartmenu pages (`SchemaOrgSerializer`)
- [ ] Ensure SSR meta tag rendering on all public pages (title, description, og:*, twitter:*)
- [ ] Add `SitemapGeneratorJob` — XML sitemap auto-generated nightly
- [ ] Ping search engines on sitemap update (Google, Bing)
- [ ] Review and update `robots.txt` for AI crawler directives
- [ ] Audit TTFB and evaluate CDN (Cloudflare)

### Phase 2 — Geo Pages (Week 2–3)

- [ ] Build `ExploreController` with geo-structured listing routes
- [ ] Launch geo pages for 1 city (Dublin) — `/explore/ireland/dublin/*`
- [ ] Internal linking between restaurants, cities, and categories
- [ ] Structured data on all listing pages (`ItemList` schema)
- [ ] Multilingual support via existing locale system

### Phase 3 — Content Engine (Week 3–4)

- [ ] Create `LocalGuide` model and admin CRUD
- [ ] Build `LocalGuideGeneratorJob` — AI-assisted guides grounded in real restaurant data
- [ ] Publish 10 high-quality local guides tied to real restaurants
- [ ] FAQ structured data on guide pages
- [ ] Auto-regeneration when underlying menu data changes

### Phase 4 — API & Moat (Week 4+)

- [ ] Design read-only public Menu Data API (`/api/v2/`)
- [ ] Rate limiting and API key management
- [ ] Attribution requirements and documentation
- [ ] Developer landing page
- [ ] Monitor: indexed pages, impressions, AI citations (test with Perplexity)

### Ongoing

- [ ] Backlink outreach (food bloggers, tourism sites, hospitality publications)
- [ ] Monitor AI citation presence (Perplexity, ChatGPT web search, Gemini)
- [ ] Expand geo pages to additional cities based on restaurant density
- [ ] Regenerate guides and structured data as menus update

---

## 🧾 Definition of Done

- [ ] Schema.org JSON-LD on all public restaurant/menu pages, validated via Google Rich Results Test
- [ ] XML sitemap auto-generated and submitted to Google Search Console
- [ ] At least 1 city with full geo-structured listing pages live
- [ ] At least 10 AI-grounded local guides published
- [ ] Pre-rendered meta tags on all public pages
- [ ] Robots.txt reviewed for AI crawler access
- [ ] CDN evaluated and configured (if applicable)
- [ ] Monitoring in place for indexed pages, impressions, and AI citations

---

## 🔮 Future Directions

1. **AI-first SEO architecture**: DB → Rails → Structured Data → Indexing → AI ingestion pipeline
2. **Growth moat strategy for EU cities**: Systematic rollout of geo pages and guides across Europe
3. **Menu knowledge graph**: pgvector + embeddings for semantic menu search and AI-native querying

---

**Created**: February 12, 2026

**Status**: Proposed — Ready for Phase 1 implementation

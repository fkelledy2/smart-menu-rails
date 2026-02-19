# CDN Evaluation — mellow.menu

**Date**: February 2026
**Status**: Evaluated — Deferred (revisit at scale)

---

## Current Setup

- **Hosting**: Heroku (EU region)
- **SSL**: Heroku ACM (Automated Certificate Management)
- **DNS**: Managed via registrar
- **Static assets**: Rails asset pipeline, served by Heroku dynos

## TTFB Measurement Approach

To measure TTFB for smartmenu pages:

```bash
# Measure TTFB for a published smartmenu page
curl -o /dev/null -s -w "TTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" https://www.mellow.menu/smartmenus/<slug>
```

**Target**: < 200ms TTFB for smartmenu pages.

### Key Pages to Measure

| Page Type | Example URL | Notes |
|---|---|---|
| Smartmenu (claimed) | `/smartmenus/:slug` | Most critical — Schema.org JSON-LD + meta tags |
| Explore city | `/explore/ie/dublin` | New Phase 2 page |
| Guide | `/guides/:slug` | New Phase 3 page |
| API v2 | `/api/v2/restaurants` | JSON responses, cacheable |

## Cloudflare Evaluation

### Cloudflare Free Tier

| Feature | Included | Relevant? |
|---|---|---|
| Global CDN | ✅ | Yes — reduces TTFB for international visitors |
| SSL | ✅ | Already have via Heroku ACM |
| DDoS protection | ✅ | Nice to have |
| Page rules (3) | ✅ | Limited but usable |
| Cache-Control headers | ✅ | Yes — can cache static pages |
| Bot analytics | ✅ | Useful for tracking AI crawlers |

### Cloudflare Pro ($20/month)

| Feature | Added Value |
|---|---|
| Polish (image optimisation) | Low — menu pages are text-heavy |
| Mirage (lazy loading) | Low — not image-heavy |
| WAF (managed rules) | Medium — additional security |
| Cache Analytics | Medium — understand cache hit rates |
| 20 page rules | Useful for more granular caching |

### Caching Considerations

**Safe to cache (static per URL)**:
- `/explore/*` pages — regenerated nightly, content stable
- `/guides/*` pages — content changes only on admin publish
- `/api/v2/*` — public, read-only responses
- Static assets (`/assets/*`)

**Must NOT cache or must vary**:
- `/smartmenus/:slug` — JSON-LD and meta tags are URL-specific but otherwise static for published menus. Can cache with `Vary: Accept` and appropriate `Cache-Control: public, max-age=3600`.
- Any page with `Set-Cookie` headers (logged-in users)

**Recommended Cache-Control headers** (if CDN implemented):

```ruby
# In ExploreController / GuidesController
response.headers['Cache-Control'] = 'public, max-age=3600, s-maxage=86400'
response.headers['Surrogate-Control'] = 'max-age=86400'

# In Api::V2::BaseController
response.headers['Cache-Control'] = 'public, max-age=300, s-maxage=3600'
```

## Decision

### Recommendation: **Defer CDN implementation**

**Rationale**:
1. **Current traffic volume is low** — mellow.menu is in growth phase. CDN benefits are marginal at low traffic volumes.
2. **Heroku EU region** — serves the primary market (Ireland/EU) with acceptable latency.
3. **No measured TTFB problem** — measure first before optimising. If TTFB < 500ms, CDN adds complexity without significant benefit.
4. **Schema.org/meta tags are dynamic** — caching these incorrectly could serve wrong structured data to crawlers, which would be worse than slightly slower pages.
5. **Cost vs. benefit** — even the free tier adds DNS complexity and potential debugging overhead.

### When to Revisit

Implement Cloudflare CDN when any of:
- TTFB consistently > 500ms on smartmenu pages
- Monthly traffic exceeds 50,000 page views
- International traffic (non-EU) exceeds 20% of total
- AI crawler traffic volume becomes significant (monitor via Heroku logs for GPTBot, CCBot user agents)

### Action Items for Implementation (when triggered)

1. Sign up for Cloudflare free tier
2. Point DNS to Cloudflare nameservers
3. Configure SSL mode: Full (Strict)
4. Add page rules:
   - `/explore/*` → Cache Everything, Edge TTL 24h
   - `/guides/*` → Cache Everything, Edge TTL 24h
   - `/api/v2/*` → Cache Everything, Edge TTL 1h
5. Add `Cache-Control` headers to relevant controllers
6. Verify Schema.org JSON-LD is correct after CDN (test with Google Rich Results)
7. Monitor cache hit ratio via Cloudflare dashboard

---

**Author**: System-generated as part of SEO & AEO strategy implementation

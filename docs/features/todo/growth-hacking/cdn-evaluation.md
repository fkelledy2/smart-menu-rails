# CDN Evaluation — mellow.menu

## Status
- Priority Rank: #26
- Category: Post-Launch (deferred — revisit at scale triggers)
- Effort: S
- Dependencies: Sufficient production traffic to measure TTFB meaningfully

## Problem Statement
Static assets and smartmenu pages are served directly from Heroku EU dynos. At low traffic volumes this is acceptable, but as mellow.menu scales internationally, TTFB will degrade for non-EU visitors. This evaluation document defines the decision criteria for CDN adoption and the implementation steps when triggered.

## Decision: Defer CDN Implementation

Rationale:
1. Current traffic volume is low — CDN benefits are marginal at low traffic.
2. Heroku EU region serves the primary market (Ireland/EU) with acceptable latency.
3. No measured TTFB problem — measure first, optimise second.
4. Schema.org/meta tags in smartmenu pages are URL-specific — caching incorrectly could serve wrong structured data to crawlers.
5. Even the Cloudflare free tier adds DNS complexity and potential debugging overhead.

## Trigger Criteria (When to Revisit)

Implement Cloudflare CDN when ANY of the following are true:
- TTFB consistently > 500ms on smartmenu pages (measure with `curl -w "TTFB: %{time_starttransfer}s"`)
- Monthly traffic exceeds 50,000 page views
- International traffic (non-EU) exceeds 20% of total
- AI crawler traffic (GPTBot, CCBot) becomes significant

## TTFB Measurement

```bash
curl -o /dev/null -s -w "TTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" \
  https://www.mellow.menu/smartmenus/<slug>
```

Target: < 200ms TTFB for smartmenu pages.

## Implementation Plan (When Triggered)

### Phase 1: Cloudflare Free Tier
1. Sign up for Cloudflare, point DNS to Cloudflare nameservers.
2. Set SSL mode to Full (Strict).
3. Add Cache-Control headers to relevant controllers:
   - `/explore/*`, `/guides/*`: `public, max-age=3600, s-maxage=86400`
   - `/api/v2/*`: `public, max-age=300, s-maxage=3600`
   - `/smartmenus/:slug`, `/t/:public_token`: `public, max-age=300` with care — validate Schema.org JSON-LD is correct post-CDN.
4. Configure page rules: `/explore/*` → Cache Everything (Edge TTL 24h); `/guides/*` → Cache Everything (24h); `/api/v2/*` → Cache Everything (1h).
5. Verify Schema.org structured data is correct after CDN (Google Rich Results Test).

### Pages Safe to Cache
- `/explore/*` — regenerated nightly, content stable.
- `/guides/*` — content changes only on admin publish.
- `/api/v2/*` — public, read-only JSON responses.
- Static assets (`/assets/*`).

### Pages Requiring Cache Caution
- `/smartmenus/:slug` and `/t/:public_token` — JSON-LD and meta tags are URL-specific. Cache with `Vary: Accept` and short TTL.
- Any page with `Set-Cookie` headers (logged-in users) — must not cache.

## Success Criteria (If Implemented)
- TTFB drops below 200ms for the 90th percentile of smartmenu page loads.
- Schema.org structured data remains correct for all cached pages (validate with Google Rich Results Test).
- Cache hit ratio > 70% for cacheable pages.
- No increase in support tickets related to stale content.

## Out of Scope
- Cloudflare Pro features (Polish, Mirage, WAF managed rules) — evaluate after free tier proves value.
- Multi-CDN strategy — single provider (Cloudflare) for simplicity.

## Open Questions
1. Should smartmenu pages set `Cache-Control: no-store` for authenticated/session-carrying requests and `public` for anonymous? Needs investigation of current cookie/session behaviour on smartmenu pages.

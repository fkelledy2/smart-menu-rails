---
name: Naked Domain Canonical Strategy v1
description: IQ-1 implementation decisions: DomainRedirect middleware, www→naked 301, canonical URL audit across codebase (March 2026)
type: project
---

DomainRedirect Rack middleware inserted at position 0 in `config/initializers/domain_redirect.rb`. Fires only when `req.host == 'www.mellow.menu'`, returns 301 to `https://mellow.menu#{req.fullpath}`. No session, no cookies.

**Why:** `mellow.menu` apex was not registered on Heroku and did not resolve; pre-launch professionalism requirement. `www.mellow.menu` redirects to naked domain for SEO consolidation.

**How to apply:** Canonical domain is `mellow.menu` (no www). All new URLs, OG tags, mailer templates, and sitemap entries should use `https://mellow.menu`. The middleware only fires on exact host match so no loop risk.

Key codebase locations updated:
- `config/sitemap.rb` — `SitemapGenerator::Sitemap.default_host`
- `public/robots.txt` — Sitemap line
- `app/controllers/explore_controller.rb`, `guides_controller.rb` — `@canonical_url` strings
- `app/controllers/api/v2/base_controller.rb` — `X-Data-Attribution` header
- `app/controllers/smartmenus_controller.rb` — `@og_url`, `@og_image` fallback
- `app/serializers/schema_org_serializer.rb` — `smartmenu_url`
- `app/views/shared/_head.html.erb` — OG/Twitter meta defaults and canonical link
- Mailer layouts and views — all footer/body links

NOT changed: `SmartMenuBot` User-Agent strings in web scrapers (attribution strings, not canonical URLs). Terms page legal prose (legal copy, not infrastructure).

CORS (`config/initializers/cors.rb`) already included both `mellow.menu` and `www.mellow.menu` — no change needed.

Production `config.hosts` already covered `mellow.menu` and a regex for all subdomains — no change needed.

Remaining ops: DNS ANAME record at name.com + `heroku domains:add mellow.menu` + ACM certs.

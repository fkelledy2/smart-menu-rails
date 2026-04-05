---
name: Clearbit deprecated — use Hunter.io for email enrichment
description: Clearbit Enrichment API is deprecated for new sign-ups post-HubSpot acquisition (2023); Hunter.io is the approved replacement for email-to-company enrichment
type: project
---

Clearbit was acquired by HubSpot in 2023. The Clearbit Enrichment API is no longer available to new sign-ups. The `clearbit` Ruby gem is unmaintained (last commit 2022). Do not recommend Clearbit for new enrichment features.

Approved alternative: **Hunter.io** People Enrichment API (v2), called via `HTTParty` which is already in the Gemfile. Hunter.io offers 25 enrichments/month free, $49/mo for 500+. Their DPA covers GDPR B2B enrichment use cases.

**Why:** Evaluated for spec #39 (Lead Enrichment + Contact Form Spam Protection, 2026-04-04). Clearbit explicitly rejected due to API deprecation; Hunter.io selected.

**How to apply:** Whenever a feature spec requires email-to-company enrichment, recommend Hunter.io + HTTParty. No new gem required. Environment variable: `HUNTER_IO_API_KEY`.

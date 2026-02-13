# SEO & Answer Engine Optimization (AEO) — Development Technical Specification

## 📋 Feature Overview

**Feature Name**: SEO & Answer Engine Optimization (AEO)

**Priority**: High

**Category**: Growth Hacking / SEO / AI Discovery / Infrastructure

**Estimated Effort**: Large (4 phases, ~6–8 weeks total)

**Target Release**: 2026

**Status**: Development-Ready

## 🥅 Overall Goals

1. Position mellow.menu as the **canonical structured source for restaurant menus** that AI systems trust and cite.
2. Shift from traditional SEO to **AEO** (Answer Engine Optimization) — be the answer inside AI assistants, voice search, and vertical discovery platforms.
3. Build a scalable, automated structured-data and content engine on the existing Rails 7.2 + Sidekiq + Heroku stack.
4. Create a defensible data moat: structured menus, allergens, pricing, and pairings become infrastructure that AI models depend on.

## 🔗 Related Specifications / References

- Claim Your Restaurant growth engine: `../../done/city-menu-crawler-claim-your-restaurant.md`
- Admin pattern (separate Admin namespace, super admin gating): `../../super-admin-impersonation-act-as-user.md`

---

## Strategic Context

### The Shift: SEO → AEO

Search behaviour is fragmenting across Google, AI assistants (ChatGPT, Gemini, Claude, Grok, Perplexity), voice search, in-app AI (maps, booking platforms), and vertical discovery (Instagram, TikTok, Apple Maps).

The goal is no longer "get traffic." The goal is:

> **Become the canonical structured source for restaurant menus.**

### Mellow's Existing Advantage

The platform already holds:

- **Structured menu data** — `restaurants`, `menus`, `menusections`, `menuitems` with prices, descriptions, sequences
- **Multilingual content** — 10+ locales via `restaurantlocales`, `menulocales`, `menusectionlocales`
- **AI-enhanced descriptions** — LLM-generated via `OcrMenuImportPolisherJob` / `AiMenuPolisherJob`
- **Allergen tagging** — via `menuitem_allergyn_mappings` → `allergyns`
- **Sommelier data** — `sommelier_category`, `abv`, `sommelier_parsed_fields` on `menuitems`
- **Geo-location** — `latitude`, `longitude`, `city`, `country`, `address1` on `restaurants`
- **Establishment types** — `establishment_types[]` array on `restaurants`
- **Claim status** — `claim_status` enum (`unclaimed`, `soft_claimed`, `claimed`, `verified`)
- **Preview system** — `preview_enabled`, `preview_indexable`, `preview_published_at`

### Anti-Patterns (What NOT To Do)

- No blog spam or mass-generated thin articles
- No thin pages without real data backing them
- No duplicate menu content across multiple URLs
- No keyword stuffing
- No JS-only rendered SEO-critical content

---

# Phase 1 — Structured Data Foundation

**Duration**: Week 1–2

**Dependencies**: None (builds on existing models)

## 1.1 Schema.org JSON-LD on Smartmenu Pages

### Overview

Every public `/smartmenus/:slug` page must emit a JSON-LD `<script>` block in `<head>` containing full Schema.org structured data derived from existing ActiveRecord models.

### Implementation Steps

- [ ] Create `app/serializers/schema_org_serializer.rb`
- [ ] Create `app/views/shared/_schema_org_json_ld.html.erb` partial
- [ ] Add JSON-LD render call to `app/views/layouts/smartmenu.html.erb` `<head>`
- [ ] Set `@schema_org_json_ld` in `SmartmenusController#show`
- [ ] Write unit test: `test/serializers/schema_org_serializer_test.rb`
- [ ] Write integration test: request spec asserting JSON-LD in response body
- [ ] Validate output via Google Rich Results Test

### New File: `app/serializers/schema_org_serializer.rb`

A plain Ruby class (no gem dependency) that accepts a restaurant + menu context and returns a Hash suitable for `JSON.generate`.

```ruby
class SchemaOrgSerializer
  def initialize(restaurant:, menu:, menusections:, smartmenu:)
    @restaurant = restaurant
    @menu = menu
    @menusections = menusections
    @smartmenu = smartmenu
  end

  def to_json_ld
    JSON.generate(restaurant_with_menu)
  end

  private

  def restaurant_with_menu
    {
      "@context" => "https://schema.org",
      "@type" => "Restaurant",
      "name" => @restaurant.name,
      "description" => @restaurant.description,
      "url" => smartmenu_url,
      "address" => address_hash,
      "geo" => geo_hash,
      "menu" => menu_hash,
      "servesCuisine" => @restaurant.establishment_types,
    }.compact
  end

  def address_hash
    return nil if @restaurant.address1.blank?
    {
      "@type" => "PostalAddress",
      "streetAddress" => [@restaurant.address1, @restaurant.address2].compact.join(", "),
      "addressLocality" => @restaurant.city,
      "addressRegion" => @restaurant.state,
      "postalCode" => @restaurant.postcode,
      "addressCountry" => @restaurant.country,
    }.compact
  end

  def geo_hash
    return nil if @restaurant.latitude.blank? || @restaurant.longitude.blank?
    {
      "@type" => "GeoCoordinates",
      "latitude" => @restaurant.latitude,
      "longitude" => @restaurant.longitude,
    }
  end

  def menu_hash
    {
      "@type" => "Menu",
      "name" => @menu.name,
      "hasMenuSection" => @menusections.map { |s| menu_section_hash(s) },
    }
  end

  def menu_section_hash(section)
    {
      "@type" => "MenuSection",
      "name" => section.name,
      "description" => section.description,
      "hasMenuItem" => section.menuitems.active.map { |item| menu_item_hash(item) },
    }.compact
  end

  def menu_item_hash(item)
    hash = {
      "@type" => "MenuItem",
      "name" => item.name,
      "description" => item.description,
    }
    if item.price.present? && item.price > 0
      hash["offers"] = {
        "@type" => "Offer",
        "price" => item.price,
        "priceCurrency" => @restaurant.currency || "EUR",
      }
    end
    if item.calories.present? && item.calories > 0
      hash["nutrition"] = {
        "@type" => "NutritionInformation",
        "calories" => "#{item.calories} cal",
      }
    end
    hash.compact
  end

  def smartmenu_url
    "https://www.mellow.menu/smartmenus/#{@smartmenu.slug}"
  end
end
```

### Schema types to emit per page type

| Page | Schema.org Type | Source Models |
|---|---|---|
| `/smartmenus/:slug` | `Restaurant` + `Menu` + `MenuSection` + `MenuItem` + `Offer` + `GeoCoordinates` | `Restaurant`, `Menu`, `Menusection`, `Menuitem` |
| `/explore/:country/:city` | `ItemList` of `Restaurant` | `Restaurant` (query) |
| `/explore/:country/:city/:category` | `ItemList` of `Restaurant` | `Restaurant` (filtered query) |
| `/guides/:slug` | `Article` + `FAQPage` | `LocalGuide` (Phase 3) |
| `/` (home) | `Organization` + `WebSite` | Static |

### Integration into Smartmenu Layout

In `app/views/layouts/smartmenu.html.erb`, add inside `<head>`:

```erb
<%= render 'shared/schema_org_json_ld' if @schema_org_json_ld.present? %>
```

New partial `app/views/shared/_schema_org_json_ld.html.erb`:

```erb
<script type="application/ld+json">
  <%= @schema_org_json_ld.html_safe %>
</script>
```

Set `@schema_org_json_ld` in `SmartmenusController#show`:

```ruby
# In SmartmenusController#show, after load_menu_associations_for_show:
@schema_org_json_ld = SchemaOrgSerializer.new(
  restaurant: @restaurant,
  menu: @menu,
  menusections: @menu.menusections.includes(:menuitems).where(archived: false),
  smartmenu: @smartmenu,
).to_json_ld
```

### Acceptance Criteria

- [ ] Every public smartmenu page renders a valid JSON-LD `<script>` block
- [ ] JSON-LD passes [Google Rich Results Test](https://search.google.com/test/rich-results)
- [ ] Restaurant name, address, geo, menu sections, and items with prices are all present
- [ ] Allergen data included where `menuitem_allergyn_mappings` exist
- [ ] No JSON-LD rendered on admin/authenticated-only pages
- [ ] Performance: serialization adds <50ms to page load

### Tests

- [ ] **Unit test**: `test/serializers/schema_org_serializer_test.rb` — verify JSON structure for restaurants with/without address, geo, allergens, prices
- [ ] **Integration test**: Request spec hitting `/smartmenus/:slug` and asserting JSON-LD script tag in response body

---

## 1.2 Dynamic Meta Tags on Smartmenu Pages

### Overview

The current `app/views/shared/_head.html.erb` has hardcoded meta tags. Smartmenu pages need dynamic `title`, `description`, `og:*`, `twitter:*`, `canonical`, and `geo.*` tags.

### Implementation Steps

- [ ] Set dynamic meta tag instance variables in `SmartmenusController#show`
- [ ] Update `app/views/shared/_head.html.erb` — dynamic OG/Twitter/canonical/geo with fallbacks
- [ ] Write request spec: smartmenu page has restaurant-specific meta tags
- [ ] Write request spec: home page retains default meta tags (no regression)

### Approach

Use existing `@page_title` and `@page_description` instance variables (already supported in `_head.html.erb` line 1 and 7) plus new variables for OG/canonical/geo.

**Set in `SmartmenusController#show`:**

```ruby
@page_title = "#{@restaurant.name} — Menu | mellow.menu"
@page_description = "View the menu for #{@restaurant.name}" +
  (@restaurant.city.present? ? " in #{@restaurant.city}" : "") +
  ". Prices, allergens, and descriptions."
@og_title = @page_title
@og_description = @page_description
@og_url = "https://www.mellow.menu/smartmenus/#{@smartmenu.slug}"
@og_image = @restaurant.image_url || "https://www.mellow.menu/images/featured-dish.jpg"
@canonical_url = @og_url
@geo_lat = @restaurant.latitude
@geo_lng = @restaurant.longitude
@geo_city = @restaurant.city
```

**Update `_head.html.erb`** to use these variables with fallbacks:

```erb
<!-- title already works: -->
<title><%= @page_title.presence || t('shared.head.meta_title') %></title>

<!-- Open Graph: make dynamic with fallbacks -->
<meta property="og:title" content="<%= @og_title.presence || t('shared.head.og_title') %>">
<meta property="og:description" content="<%= @og_description.presence || t('shared.head.og_description') %>">
<meta property="og:image" content="<%= @og_image.presence || 'https://www.mellow.menu/images/featured-dish.jpg' %>">
<meta property="og:url" content="<%= @og_url.presence || 'https://www.mellow.menu' %>">

<!-- Twitter: same pattern -->
<meta name="twitter:title" content="<%= @og_title.presence || t('shared.head.twitter_title') %>">
<meta name="twitter:description" content="<%= @og_description.presence || t('shared.head.twitter_description') %>">
<meta name="twitter:image" content="<%= @og_image.presence || 'https://www.mellow.menu/images/featured-dish.jpg' %>">

<!-- Canonical: make dynamic -->
<link rel="canonical" href="<%= @canonical_url.presence || 'https://www.mellow.menu' %>">

<!-- Geo: make dynamic -->
<% if @geo_lat.present? && @geo_lng.present? %>
  <meta name="geo.position" content="<%= @geo_lat %>;<%= @geo_lng %>">
  <meta name="ICBM" content="<%= @geo_lat %>, <%= @geo_lng %>">
<% else %>
  <meta name="geo.position" content="53.349805;-6.26031">
  <meta name="ICBM" content="53.349805, -6.26031">
<% end %>
<meta name="geo.placename" content="<%= @geo_city.presence || 'Dublin' %>">
```

### Acceptance Criteria

- [ ] Smartmenu pages render restaurant-specific `og:title`, `og:description`, `og:url`, `og:image`
- [ ] Canonical URL points to the specific smartmenu URL
- [ ] Geo tags reflect restaurant's actual lat/lng when available
- [ ] Non-smartmenu pages retain existing static defaults (no regression)
- [ ] Twitter card tags match OG tags

### Tests

- [ ] **Request spec**: Hit a smartmenu page, assert meta tag content matches restaurant data
- [ ] **Request spec**: Hit home page, assert default meta tags still render

---

## 1.3 Dynamic XML Sitemap

### Overview

`config/sitemap.rb` exists using the `sitemap_generator` gem but only has 3 static URLs and the dynamic smartmenu loop is commented out. Enable it and add all public page types.

### Implementation Steps

- [ ] Update `config/sitemap.rb` — enable smartmenu loop, add commented explore/guide sections
- [ ] Create `app/jobs/sitemap_generator_job.rb`
- [ ] Add Sidekiq cron entry for nightly sitemap regeneration
- [ ] Write unit test for `SitemapGeneratorJob`
- [ ] Run `rake sitemap:refresh` and verify output

### Update `config/sitemap.rb`

```ruby
SitemapGenerator::Sitemap.default_host = 'https://www.mellow.menu'
SitemapGenerator::Sitemap.create do
  # Static pages
  add '/', priority: 1.0, changefreq: 'daily'
  add '/terms', priority: 0.3, changefreq: 'monthly'
  add '/privacy', priority: 0.3, changefreq: 'monthly'

  # All published smartmenus (public menu pages)
  Smartmenu.includes(:restaurant, :menu)
    .joins(:restaurant)
    .where(tablesetting_id: nil)
    .where(restaurants: { preview_enabled: true })
    .find_each do |sm|
    add "/smartmenus/#{sm.slug}",
        lastmod: [sm.updated_at, sm.menu&.updated_at, sm.restaurant&.updated_at].compact.max,
        changefreq: 'weekly',
        priority: 0.8
  end

  # Explore pages (Phase 2 — uncomment when ExploreController is live)
  # ExplorePage.published.find_each do |page|
  #   add page.path, lastmod: page.updated_at, changefreq: 'weekly', priority: 0.7
  # end

  # Local guides (Phase 3 — uncomment when LocalGuide is live)
  # LocalGuide.published.find_each do |guide|
  #   add "/guides/#{guide.slug}", lastmod: guide.updated_at, changefreq: 'weekly', priority: 0.6
  # end
end
```

### New Job: `app/jobs/sitemap_generator_job.rb`

```ruby
class SitemapGeneratorJob < ApplicationJob
  queue_as :low

  def perform
    SitemapGenerator::Interpreter.run
    SitemapGenerator::Sitemap.ping_search_engines
    Rails.logger.info("[SitemapGeneratorJob] Sitemap regenerated and search engines pinged")
  end
end
```

### Sidekiq Cron (add to `config/initializers/sidekiq_cron.rb` or equivalent)

```ruby
# Nightly sitemap regeneration at 3am UTC
Sidekiq::Cron::Job.create(
  name: 'Sitemap Generator - nightly',
  cron: '0 3 * * *',
  class: 'SitemapGeneratorJob',
)
```

### Acceptance Criteria

- [ ] `rake sitemap:refresh` generates a valid `sitemap.xml.gz` with all published smartmenu URLs
- [ ] Sitemap includes `lastmod` timestamps derived from restaurant/menu `updated_at`
- [ ] `SitemapGeneratorJob` runs nightly via Sidekiq cron
- [ ] Search engines (Google, Bing) are pinged after regeneration
- [ ] Sitemap URL in `robots.txt` matches generated file location

### Tests

- [ ] **Unit test**: Verify `SitemapGeneratorJob#perform` calls `SitemapGenerator::Interpreter.run`
- [ ] **Integration**: Run `rake sitemap:refresh` in test, verify output file exists

---

## 1.4 Robots.txt Update

### Overview

Current `public/robots.txt` is mostly correct. Two additions needed:

1. Add `Disallow: /madmin` (admin interface)
2. Explicitly allow `/explore/` and `/guides/` paths for AI crawlers (future-proofing)

### Implementation Steps

- [ ] Add `/madmin` disallow rules to `public/robots.txt`
- [ ] Update GPTBot section with explicit `/smartmenus/`, `/explore/`, `/guides/` allows
- [ ] Verify existing allows/disallows are not regressed

### Changes to `public/robots.txt`

Add after existing `Disallow: /admin/*` line:

```
Disallow: /madmin
Disallow: /madmin/*
```

Add explicit allows for GPTBot:

```
User-agent: GPTBot
Allow: /smartmenus/
Allow: /explore/
Allow: /guides/
```

### Acceptance Criteria

- [ ] `/madmin` paths are disallowed for all crawlers
- [ ] GPTBot has explicit allows for public content paths
- [ ] Existing allows/disallows are not regressed

---

## 1.5 CDN Evaluation

### Overview

Evaluate Cloudflare (or alternative) for CDN in front of Heroku to improve TTFB.

### Implementation Steps

- [ ] Measure current TTFB for smartmenu pages (target: <200ms)
- [ ] Evaluate Cloudflare free tier vs Pro for Heroku
- [ ] If TTFB >500ms, implement Cloudflare with appropriate cache rules
- [ ] Ensure JSON-LD and meta tags are not cached incorrectly (vary by URL)

### Acceptance Criteria

- [ ] TTFB measured and documented
- [ ] CDN decision documented (implement or defer with rationale)

---

# Phase 2 — Geo/Explore Pages

**Duration**: Week 3–4

**Dependencies**: Phase 1 (structured data + sitemap infrastructure)

## 2.1 Explore Pages Data Model

### Overview

Explore pages are dynamically generated from existing restaurant data. No new database table is required for the pages themselves — they're query-driven. However, we need a cache/lookup table to know which country/city/category combinations have enough restaurants to warrant a page.

### Implementation Steps

- [ ] Create migration `db/migrate/XXX_create_explore_pages.rb`
- [ ] Run migration
- [ ] Create `app/models/explore_page.rb`
- [ ] Write model test for `ExplorePage` (validations, scopes, `#restaurants`, `#path`)

### New Migration: `explore_pages`

```ruby
class CreateExplorePages < ActiveRecord::Migration[7.2]
  def change
    create_table :explore_pages do |t|
      t.string :country_slug, null: false   # "ireland", "italy"
      t.string :country_name, null: false   # "Ireland", "Italy"
      t.string :city_slug, null: false      # "dublin", "florence"
      t.string :city_name, null: false      # "Dublin", "Florence"
      t.string :category_slug              # "italian", "vegan", nil for city-level pages
      t.string :category_name              # "Italian", "Vegan"
      t.integer :restaurant_count, default: 0, null: false
      t.text :meta_title
      t.text :meta_description
      t.datetime :last_refreshed_at
      t.boolean :published, default: false, null: false

      t.timestamps
    end

    add_index :explore_pages, [:country_slug, :city_slug, :category_slug],
              unique: true, name: 'idx_explore_pages_unique_path'
    add_index :explore_pages, :published
    add_index :explore_pages, :restaurant_count
  end
end
```

### New Model: `app/models/explore_page.rb`

```ruby
class ExplorePage < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :city_level, -> { where(category_slug: nil) }
  scope :with_restaurants, -> { where('restaurant_count > 0') }

  validates :country_slug, :country_name, :city_slug, :city_name, presence: true
  validates :category_slug, uniqueness: { scope: [:country_slug, :city_slug], allow_nil: true }

  def path
    if category_slug.present?
      "/explore/#{country_slug}/#{city_slug}/#{category_slug}"
    else
      "/explore/#{country_slug}/#{city_slug}"
    end
  end

  # Returns restaurants for this explore page
  def restaurants
    scope = Restaurant.where(preview_enabled: true)
                      .where("LOWER(city) = ?", city_name.downcase)
                      .where("LOWER(country) = ?", country_name.downcase)

    if category_slug.present?
      scope = scope.where("? = ANY(establishment_types)", category_name)
    end

    scope.order(
      Arel.sql("CASE WHEN claim_status IN (2,3) THEN 0 ELSE 1 END ASC"),
      :name
    )
  end
end
```

### Display Strategy: Tiered

Restaurants are displayed in two tiers:

1. **Claimed/Verified** (claim_status 2, 3): Full card with name, description, cuisine types, link to menu
2. **Unclaimed** (claim_status 0, 1): Lighter card with name, basic info, "Claim this restaurant" CTA, disclaimer badge

---

## 2.2 Routes

### Implementation Steps

- [ ] Add explore routes to `config/routes.rb`
- [ ] Create `app/controllers/explore_controller.rb`
- [ ] Write controller test: 200 for valid page, 404 for invalid

### Add to `config/routes.rb`

```ruby
# ============================================================================
# EXPLORE PAGES (SEO / Geo)
# ============================================================================
scope :explore, controller: 'explore' do
  get '/:country/:city/:category', action: :show, as: :explore_category
  get '/:country/:city', action: :city, as: :explore_city
  get '/:country', action: :country, as: :explore_country
  get '/', action: :index, as: :explore_index
end
```

### New Controller: `app/controllers/explore_controller.rb`

```ruby
class ExploreController < ApplicationController
  # No authentication required — public pages
  skip_before_action :authenticate_user!, raise: false

  layout 'application' # or a dedicated 'explore' layout

  def index
    @countries = ExplorePage.published.select(:country_slug, :country_name)
                            .distinct.order(:country_name)
  end

  def country
    @country = params[:country]
    @cities = ExplorePage.published
                         .where(country_slug: @country)
                         .city_level
                         .order(:city_name)
    render_404 if @cities.empty?
  end

  def city
    @page = ExplorePage.published.find_by!(
      country_slug: params[:country],
      city_slug: params[:city],
      category_slug: nil,
    )
    @restaurants = @page.restaurants.includes(:menus, :smartmenus)
    @categories = ExplorePage.published
                             .where(country_slug: params[:country], city_slug: params[:city])
                             .where.not(category_slug: nil)
                             .order(:category_name)
    set_explore_meta_tags
    set_explore_schema_org
  end

  def show
    @page = ExplorePage.published.find_by!(
      country_slug: params[:country],
      city_slug: params[:city],
      category_slug: params[:category],
    )
    @restaurants = @page.restaurants.includes(:menus, :smartmenus)
    set_explore_meta_tags
    set_explore_schema_org
  end

  private

  def set_explore_meta_tags
    @page_title = @page.meta_title.presence ||
      "#{@page.category_name} Restaurants in #{@page.city_name}, #{@page.country_name} | mellow.menu"
    @page_description = @page.meta_description.presence ||
      "Discover #{@page.category_name&.downcase || ''} restaurants in #{@page.city_name}. View menus, prices, and allergen info."
    @canonical_url = "https://www.mellow.menu#{@page.path}"
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def set_explore_schema_org
    items = @restaurants.limit(50).map.with_index do |r, i|
      {
        "@type" => "ListItem",
        "position" => i + 1,
        "item" => {
          "@type" => "Restaurant",
          "name" => r.name,
          "address" => { "@type" => "PostalAddress", "addressLocality" => r.city }.compact,
          "servesCuisine" => r.establishment_types,
        }.compact,
      }
    end

    @schema_org_json_ld = JSON.generate({
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => @page_title,
      "numberOfItems" => @restaurants.count,
      "itemListElement" => items,
    })
  end

  def render_404
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end
end
```

---

## 2.3 Explore Page Generator Job

### Implementation Steps

- [ ] Create `app/jobs/explore_page_generator_job.rb`
- [ ] Add Sidekiq cron entry (3:30am UTC nightly)
- [ ] Write job test: creates pages from restaurant data, unpublishes stale pages

### New Job: `app/jobs/explore_page_generator_job.rb`

Discovers valid country/city/category combinations from restaurant data and creates/updates `ExplorePage` records.

```ruby
class ExplorePageGeneratorJob < ApplicationJob
  queue_as :low

  MIN_RESTAURANTS_FOR_PAGE = 2  # Minimum restaurants to create a page

  def perform
    generate_city_pages
    generate_category_pages
    unpublish_empty_pages
    Rails.logger.info("[ExplorePageGeneratorJob] Refresh complete")
  end

  private

  def generate_city_pages
    Restaurant.where(preview_enabled: true)
              .where.not(city: [nil, ''])
              .where.not(country: [nil, ''])
              .group(:city, :country)
              .having("COUNT(*) >= ?", MIN_RESTAURANTS_FOR_PAGE)
              .count
              .each do |(city, country), count|
      page = ExplorePage.find_or_initialize_by(
        country_slug: country.parameterize,
        city_slug: city.parameterize,
        category_slug: nil,
      )
      page.assign_attributes(
        country_name: country,
        city_name: city,
        restaurant_count: count,
        published: true,
        last_refreshed_at: Time.current,
      )
      page.save!
    end
  end

  def generate_category_pages
    # For each city, find establishment_types with enough restaurants
    Restaurant.where(preview_enabled: true)
              .where.not(city: [nil, ''])
              .where.not(establishment_types: [])
              .find_each do |r|
      r.establishment_types.each do |etype|
        key = [r.city.parameterize, r.country.parameterize, etype.parameterize]
        # Batch these to avoid N+1
        @category_counts ||= Hash.new(0)
        @category_counts[key] += 1
        @category_names ||= {}
        @category_names[key] = [r.city, r.country, etype]
      end
    end

    (@category_counts || {}).each do |key, count|
      next if count < MIN_RESTAURANTS_FOR_PAGE
      city, country, category = @category_names[key]

      page = ExplorePage.find_or_initialize_by(
        country_slug: country.parameterize,
        city_slug: city.parameterize,
        category_slug: category.parameterize,
      )
      page.assign_attributes(
        country_name: country,
        city_name: city,
        category_name: category,
        restaurant_count: count,
        published: true,
        last_refreshed_at: Time.current,
      )
      page.save!
    end
  end

  def unpublish_empty_pages
    ExplorePage.where(published: true)
               .where("last_refreshed_at < ? OR last_refreshed_at IS NULL", 1.hour.ago)
               .update_all(published: false)
  end
end
```

### Sidekiq Cron

```ruby
Sidekiq::Cron::Job.create(
  name: 'Explore Page Generator - nightly',
  cron: '30 3 * * *',  # 3:30am UTC, after sitemap
  class: 'ExplorePageGeneratorJob',
)
```

---

## 2.4 Views

### Implementation Steps

- [ ] Create `app/views/explore/index.html.erb`
- [ ] Create `app/views/explore/country.html.erb`
- [ ] Create `app/views/explore/city.html.erb`
- [ ] Create `app/views/explore/show.html.erb`
- [ ] Create `app/views/explore/_restaurant_card.html.erb` (claimed + unclaimed variants)
- [ ] Create `app/views/explore/_breadcrumbs.html.erb`
- [ ] Uncomment explore section in `config/sitemap.rb`
- [ ] Write request spec: verify JSON-LD and meta tags on explore pages

### Required View Files

| File | Purpose |
|---|---|
| `app/views/explore/index.html.erb` | Country listing page |
| `app/views/explore/country.html.erb` | City listing for a country |
| `app/views/explore/city.html.erb` | Restaurant listing for a city |
| `app/views/explore/show.html.erb` | Restaurant listing for city + category |
| `app/views/explore/_restaurant_card.html.erb` | Partial: restaurant card (claimed vs unclaimed variants) |
| `app/views/explore/_breadcrumbs.html.erb` | Partial: breadcrumb navigation (country > city > category) |

### Internal Linking Requirements

Every explore page must include:

- Breadcrumb navigation (country → city → category)
- Links to sibling categories within the same city
- Links to individual restaurant smartmenu pages
- Link back to explore index

### Acceptance Criteria

- [ ] `ExplorePageGeneratorJob` discovers city/category combos from restaurant data
- [ ] Explore pages render with correct restaurants, tiered by claim status
- [ ] Claimed restaurants displayed prominently; unclaimed show "Claim this listing" CTA
- [ ] Schema.org `ItemList` JSON-LD on every explore page
- [ ] Dynamic meta tags (title, description, canonical, OG) per page
- [ ] Internal linking between explore pages and smartmenu pages
- [ ] Breadcrumb navigation on all explore pages
- [ ] Explore pages added to sitemap (uncomment block in `config/sitemap.rb`)
- [ ] Pages with <2 restaurants are not published

### Tests

- [ ] **Model test**: `ExplorePage#restaurants` returns correct filtered set, ordered by claim status
- [ ] **Controller test**: `ExploreController#show` returns 200 for valid page, 404 for invalid
- [ ] **Job test**: `ExplorePageGeneratorJob` creates pages from restaurant data, unpublishes stale pages
- [ ] **Request spec**: Verify JSON-LD and meta tags on explore pages

---

# Phase 3 — AI Local Guides (Content Engine)

**Duration**: Week 4–5

**Dependencies**: Phase 1 (structured data), Phase 2 (explore pages for internal linking)

## 3.1 LocalGuide Model

### Implementation Steps

- [ ] Create migration `db/migrate/XXX_create_local_guides.rb`
- [ ] Run migration
- [ ] Create `app/models/local_guide.rb`
- [ ] Write model test (validations, scopes, slug generation, status enum)

### New Migration: `local_guides`

```ruby
class CreateLocalGuides < ActiveRecord::Migration[7.2]
  def change
    create_table :local_guides do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :city, null: false
      t.string :country, null: false
      t.string :category                    # "gluten-free", "wine-pairings", etc.
      t.text :content, null: false           # Rendered markdown/HTML
      t.text :content_source                 # Raw LLM output before editing
      t.jsonb :referenced_restaurants, default: []  # [{id:, name:, menuitem_ids: []}]
      t.jsonb :faq_data, default: []         # [{question:, answer:}]
      t.integer :status, default: 0, null: false  # draft, published, archived
      t.datetime :published_at
      t.datetime :regenerated_at
      t.bigint :approved_by_user_id          # super_admin who approved

      t.timestamps
    end

    add_index :local_guides, :slug, unique: true
    add_index :local_guides, :status
    add_index :local_guides, [:city, :category]
    add_index :local_guides, :approved_by_user_id
  end
end
```

### New Model: `app/models/local_guide.rb`

```ruby
class LocalGuide < ApplicationRecord
  belongs_to :approved_by_user, class_name: 'User', optional: true

  enum :status, { draft: 0, published: 1, archived: 2 }

  scope :published, -> { where(status: :published) }

  validates :title, :slug, :city, :country, :content, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= "#{city}-#{category}-#{SecureRandom.hex(4)}".parameterize
  end
end
```

## 3.2 Admin CRUD

### Implementation Steps

- [ ] Add `local_guides` routes to admin namespace in `config/routes.rb`
- [ ] Create `app/controllers/admin/local_guides_controller.rb`
- [ ] Create `app/policies/local_guide_policy.rb` (super_admin only for approve)
- [ ] Create `app/views/admin/local_guides/index.html.erb`
- [ ] Create `app/views/admin/local_guides/show.html.erb`
- [ ] Create `app/views/admin/local_guides/new.html.erb`
- [ ] Create `app/views/admin/local_guides/edit.html.erb`
- [ ] Write controller test: admin approve/archive flow
- [ ] Write policy test: only super_admin can approve

### Routes (add to admin namespace)

```ruby
# In config/routes.rb, within the admin namespace:
namespace :admin do
  resources :local_guides do
    member do
      patch :approve
      patch :archive
      post :regenerate
    end
  end
end
```

### Controller: `app/controllers/admin/local_guides_controller.rb`

Standard admin CRUD with:

- `index`: List all guides with status filter tabs (draft/published/archived)
- `show`: Preview guide content with referenced restaurants
- `approve`: Set status to `published`, `published_at` to now, `approved_by_user_id` to current user
- `archive`: Set status to `archived`
- `regenerate`: Enqueue `LocalGuideGeneratorJob` for this guide

### Admin Views

| File | Purpose |
|---|---|
| `app/views/admin/local_guides/index.html.erb` | List with status tabs |
| `app/views/admin/local_guides/show.html.erb` | Preview with approve/archive buttons |
| `app/views/admin/local_guides/new.html.erb` | Manual create form (city, category, optional seed content) |
| `app/views/admin/local_guides/edit.html.erb` | Edit content before approval |

## 3.3 Guide Generator Job

### Implementation Steps

- [ ] Create `app/jobs/local_guide_generator_job.rb`
- [ ] Write job test: mock OpenAI, verify guide creation with correct references
- [ ] Generate initial batch of 10 guides for Dublin (draft)
- [ ] Admin review and publish initial guides

### New Job: `app/jobs/local_guide_generator_job.rb`

```ruby
class LocalGuideGeneratorJob < ApplicationJob
  queue_as :default

  def perform(local_guide_id: nil, city: nil, category: nil)
    if local_guide_id
      guide = LocalGuide.find(local_guide_id)
      regenerate_guide(guide)
    else
      generate_new_guide(city: city, category: category)
    end
  end

  private

  def generate_new_guide(city:, category:)
    restaurants = fetch_restaurants(city, category)
    return if restaurants.empty?

    prompt = build_prompt(city, category, restaurants)
    response = call_openai(prompt)

    LocalGuide.create!(
      title: "#{category&.titleize || 'Best'} Restaurants in #{city}",
      city: city,
      country: infer_country(city),
      category: category,
      content: response[:content],
      content_source: response[:raw],
      referenced_restaurants: build_references(restaurants),
      faq_data: response[:faq] || [],
      status: :draft,
      regenerated_at: Time.current,
    )
  end

  def regenerate_guide(guide)
    restaurants = fetch_restaurants(guide.city, guide.category)
    prompt = build_prompt(guide.city, guide.category, restaurants)
    response = call_openai(prompt)

    guide.update!(
      content: response[:content],
      content_source: response[:raw],
      referenced_restaurants: build_references(restaurants),
      faq_data: response[:faq] || [],
      regenerated_at: Time.current,
      status: :draft,  # Reset to draft for re-approval
    )
  end

  def fetch_restaurants(city, category)
    scope = Restaurant.where(preview_enabled: true)
                      .where("LOWER(city) = ?", city.downcase)
                      .includes(menus: { menusections: :menuitems })
    if category.present?
      scope = scope.where("? = ANY(establishment_types)", category)
    end
    scope.limit(20)
  end

  def build_prompt(city, category, restaurants)
    restaurant_data = restaurants.map do |r|
      items = r.menus.flat_map { |m| m.menusections.flat_map(&:menuitems) }
                     .select { |i| i.status == 'active' rescue true }
                     .first(10)
      {
        name: r.name,
        description: r.description,
        items: items.map { |i| { name: i.name, description: i.description, price: i.price } },
      }
    end

    <<~PROMPT
      Write a concise, informative local guide about #{category || 'dining'} in #{city}.

      Ground every recommendation in the following real restaurant data. Do not invent
      restaurants or dishes. Reference specific dish names and prices where relevant.

      Restaurant data:
      #{JSON.pretty_generate(restaurant_data)}

      Requirements:
      - 400-600 words
      - Include 3-5 specific dish recommendations with prices
      - Include 3 FAQ questions and answers (JSON array: [{question, answer}])
      - Professional tone, useful for tourists and locals
      - Output format: JSON with keys "content" (HTML string) and "faq" (array)
    PROMPT
  end

  def call_openai(prompt)
    client = OpenAI::Client.new
    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a knowledgeable local food guide writer." },
        { role: "user", content: prompt },
      ],
      temperature: 0.7,
    })
    raw = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(raw)
    { content: parsed["content"], faq: parsed["faq"], raw: raw }
  rescue JSON::ParserError
    { content: raw, faq: [], raw: raw }
  end

  def build_references(restaurants)
    restaurants.map do |r|
      { id: r.id, name: r.name, menuitem_ids: r.menus.flat_map { |m| m.menuitems.pluck(:id) }.first(20) }
    end
  end

  def infer_country(city)
    Restaurant.where("LOWER(city) = ?", city.downcase)
              .where.not(country: [nil, ''])
              .limit(1).pick(:country) || "Unknown"
  end
end
```

## 3.4 Public Guide Pages

### Implementation Steps

- [ ] Add public guide routes to `config/routes.rb`
- [ ] Create `app/controllers/guides_controller.rb`
- [ ] Create `app/views/guides/index.html.erb`
- [ ] Create `app/views/guides/show.html.erb`
- [ ] Uncomment guides section in `config/sitemap.rb`
- [ ] Write request spec: public show with Article + FAQPage JSON-LD

### Routes

```ruby
# Public guide pages
resources :guides, only: [:index, :show], param: :slug, controller: 'guides'
```

### Controller: `app/controllers/guides_controller.rb`

```ruby
class GuidesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def index
    @guides = LocalGuide.published.order(published_at: :desc)
  end

  def show
    @guide = LocalGuide.published.find_by!(slug: params[:slug])
    set_guide_meta_tags
    set_guide_schema_org
  end

  private

  def set_guide_meta_tags
    @page_title = "#{@guide.title} | mellow.menu"
    @page_description = @guide.content.to_s.truncate(160, separator: ' ')
    @canonical_url = "https://www.mellow.menu/guides/#{@guide.slug}"
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def set_guide_schema_org
    schema = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => @guide.title,
      "datePublished" => @guide.published_at&.iso8601,
      "dateModified" => @guide.updated_at&.iso8601,
      "publisher" => { "@type" => "Organization", "name" => "mellow.menu" },
    }

    if @guide.faq_data.present?
      schema["mainEntity"] = {
        "@type" => "FAQPage",
        "mainEntity" => @guide.faq_data.map do |faq|
          {
            "@type" => "Question",
            "name" => faq["question"],
            "acceptedAnswer" => { "@type" => "Answer", "text" => faq["answer"] },
          }
        end,
      }
    end

    @schema_org_json_ld = JSON.generate(schema)
  end
end
```

### Acceptance Criteria

- [ ] `LocalGuide` model with draft/published/archived workflow
- [ ] Admin CRUD with approve/archive/regenerate actions
- [ ] Only super_admin can approve guides (Pundit policy)
- [ ] `LocalGuideGeneratorJob` generates grounded content from real restaurant data
- [ ] Generated guides are always created as **draft** — require admin approval
- [ ] Regeneration resets status to draft for re-approval
- [ ] Public `/guides/:slug` pages render with Article + FAQPage JSON-LD
- [ ] Guides added to sitemap when published
- [ ] Internal links from guides to smartmenu pages and explore pages

### Tests

- [ ] **Model test**: Validations, scopes, slug generation
- [ ] **Job test**: Mock OpenAI, verify guide creation with correct references
- [ ] **Controller test**: Admin approve/archive flow, public show with JSON-LD
- [ ] **Policy test**: Only super_admin can approve

---

# Phase 4 — Public API v2

**Duration**: Week 5–6

**Dependencies**: Phase 1 (structured data serializer)

## 4.1 API Architecture

### Namespace: `/api/v2/`

Separate from the existing authenticated `/api/v1/`. Public, read-only, rate-limited.

### Implementation Steps

- [ ] Create `app/controllers/api/v2/base_controller.rb` (rate limiting, attribution header)
- [ ] Create `app/controllers/api/v2/restaurants_controller.rb` (index, show, menu)
- [ ] Create `app/controllers/api/v2/explore_controller.rb` (index, show)
- [ ] Add `/api/v2/` routes to `config/routes.rb`
- [ ] Write request spec: unauthenticated access returns 200 with JSON
- [ ] Write request spec: rate limit returns 429 after 100 requests
- [ ] Write request spec: response includes `X-Data-Attribution` header
- [ ] Write request spec: only published restaurants in results
- [ ] Write request spec: menu endpoint returns full structure

### New Base Controller: `app/controllers/api/v2/base_controller.rb`

```ruby
module Api
  module V2
    class BaseController < ApplicationController
      skip_before_action :authenticate_user!, raise: false
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false
      skip_around_action :switch_locale, raise: false

      before_action :enforce_rate_limit
      after_action :set_attribution_header

      private

      def enforce_rate_limit
        key = "api_v2:#{request.remote_ip}"
        count = Rails.cache.increment(key, 1, expires_in: 1.hour, initial: 0)
        if count > rate_limit
          render json: { error: "Rate limit exceeded. Max #{rate_limit} requests/hour." },
                 status: :too_many_requests
        end
      end

      def rate_limit
        100 # Unauthenticated default; API key holders get more (future)
      end

      def set_attribution_header
        response.headers['X-Data-Attribution'] = 'Data by mellow.menu — https://www.mellow.menu'
      end
    end
  end
end
```

### Routes

```ruby
namespace :api do
  namespace :v2 do
    resources :restaurants, only: [:index, :show] do
      member do
        get :menu
      end
    end
    resources :explore, only: [:index, :show], param: :path
  end
end
```

### Endpoints

| Method | Path | Description | Response |
|---|---|---|---|
| `GET` | `/api/v2/restaurants` | List restaurants (paginated, filterable by city/country/category) | JSON array of Restaurant summaries |
| `GET` | `/api/v2/restaurants/:id` | Restaurant detail with address, geo, establishment types | JSON Restaurant object |
| `GET` | `/api/v2/restaurants/:id/menu` | Full menu with sections, items, prices, allergens | JSON-LD compatible Menu object |
| `GET` | `/api/v2/explore` | List available explore pages (cities/categories) | JSON array of ExplorePage summaries |

### Response Format

All responses follow JSON-LD-compatible structure:

```json
{
  "data": {
    "@context": "https://schema.org",
    "@type": "Restaurant",
    "name": "Da Mimmo",
    "address": { ... },
    "geo": { ... },
    "menu": { ... }
  },
  "attribution": "Data by mellow.menu",
  "generated_at": "2026-02-13T12:00:00Z"
}
```

### Controllers

- `app/controllers/api/v2/restaurants_controller.rb` — index, show, menu actions
- `app/controllers/api/v2/explore_controller.rb` — index, show actions

### Acceptance Criteria

- [ ] All v2 endpoints are public (no authentication required)
- [ ] Rate limited to 100 req/hour per IP
- [ ] `X-Data-Attribution` header on every response
- [ ] JSON-LD compatible response format
- [ ] Only `preview_enabled: true` restaurants are exposed
- [ ] Pagination on list endpoints (page/per_page params, max 50 per page)
- [ ] No sensitive data exposed (no user IDs, internal status flags, etc.)

### Tests

- [ ] **Request spec**: Unauthenticated access returns 200 with JSON
- [ ] **Request spec**: Rate limit returns 429 after 100 requests
- [ ] **Request spec**: Response includes attribution header
- [ ] **Request spec**: Only published restaurants appear in results
- [ ] **Request spec**: Menu endpoint returns full section/item/price structure

---

# Cross-Cutting Concerns

## Performance

- [ ] Verify JSON-LD serialization adds <50ms to page render
- [ ] Verify explore page queries are indexed
- [ ] Consider fragment caching for Schema.org JSON-LD blocks (keyed on restaurant + menu `updated_at`)

## Database Indexes Needed

- [ ] Verify or add `idx_restaurants_geo_preview` index
- [ ] Verify or add `idx_restaurants_preview_claim` index

```ruby
# On restaurants table:
add_index :restaurants, [:city, :country, :preview_enabled], name: 'idx_restaurants_geo_preview'
add_index :restaurants, [:preview_enabled, :claim_status], name: 'idx_restaurants_preview_claim'
```

## Monitoring

- [ ] Set up Google Search Console for mellow.menu
- [ ] Track AI citations via Perplexity search tests (manual, monthly)
- [ ] Monitor sitemap generation job success via Sidekiq dashboard
- [ ] (Stretch) Create `SchemaOrgValidatorJob` for periodic structured data validation

## Backlink Strategy (Non-Technical / Ongoing)

- [ ] Outreach to food bloggers and reviewers
- [ ] Submit to local tourism sites and city directories
- [ ] Seek links from hospitality industry publications
- [ ] Seek links from restaurant association websites
- [ ] Seek links from university/college "eating out" guides

---

# File Summary

## New Files

| | File | Phase | Type |
|---|---|---|---|
| [ ] | `app/serializers/schema_org_serializer.rb` | 1 | Serializer |
| [ ] | `app/views/shared/_schema_org_json_ld.html.erb` | 1 | Partial |
| [ ] | `app/jobs/sitemap_generator_job.rb` | 1 | Job |
| [ ] | `db/migrate/XXX_create_explore_pages.rb` | 2 | Migration |
| [ ] | `app/models/explore_page.rb` | 2 | Model |
| [ ] | `app/controllers/explore_controller.rb` | 2 | Controller |
| [ ] | `app/views/explore/index.html.erb` | 2 | View |
| [ ] | `app/views/explore/country.html.erb` | 2 | View |
| [ ] | `app/views/explore/city.html.erb` | 2 | View |
| [ ] | `app/views/explore/show.html.erb` | 2 | View |
| [ ] | `app/views/explore/_restaurant_card.html.erb` | 2 | Partial |
| [ ] | `app/views/explore/_breadcrumbs.html.erb` | 2 | Partial |
| [ ] | `app/jobs/explore_page_generator_job.rb` | 2 | Job |
| [ ] | `db/migrate/XXX_create_local_guides.rb` | 3 | Migration |
| [ ] | `app/models/local_guide.rb` | 3 | Model |
| [ ] | `app/policies/local_guide_policy.rb` | 3 | Policy |
| [ ] | `app/controllers/admin/local_guides_controller.rb` | 3 | Controller |
| [ ] | `app/views/admin/local_guides/index.html.erb` | 3 | View |
| [ ] | `app/views/admin/local_guides/show.html.erb` | 3 | View |
| [ ] | `app/views/admin/local_guides/new.html.erb` | 3 | View |
| [ ] | `app/views/admin/local_guides/edit.html.erb` | 3 | View |
| [ ] | `app/controllers/guides_controller.rb` | 3 | Controller |
| [ ] | `app/views/guides/index.html.erb` | 3 | View |
| [ ] | `app/views/guides/show.html.erb` | 3 | View |
| [ ] | `app/jobs/local_guide_generator_job.rb` | 3 | Job |
| [ ] | `app/controllers/api/v2/base_controller.rb` | 4 | Controller |
| [ ] | `app/controllers/api/v2/restaurants_controller.rb` | 4 | Controller |
| [ ] | `app/controllers/api/v2/explore_controller.rb` | 4 | Controller |

## Modified Files

| | File | Phase | Changes |
|---|---|---|---|
| [ ] | `app/controllers/smartmenus_controller.rb` | 1 | Add `@schema_org_json_ld` + dynamic meta tag vars to `#show` |
| [ ] | `app/views/shared/_head.html.erb` | 1 | Dynamic OG/Twitter/canonical/geo tags with fallbacks |
| [ ] | `app/views/layouts/smartmenu.html.erb` | 1 | Render JSON-LD partial |
| [ ] | `config/sitemap.rb` | 1 | Uncomment smartmenu loop, add explore/guide sections |
| [ ] | `public/robots.txt` | 1 | Add `/madmin` disallow, GPTBot specific allows |
| [ ] | `config/routes.rb` | 2,3,4 | Add explore, guides, api/v2 routes |

---

# Definition of Done (All Phases)

- [ ] **P1**: Schema.org JSON-LD on all smartmenu pages, validated via Google Rich Results Test
- [ ] **P1**: Dynamic meta/OG tags on smartmenu pages; static pages retain defaults
- [ ] **P1**: XML sitemap generated nightly with all published smartmenu URLs
- [ ] **P1**: Robots.txt updated with `/madmin` disallow and AI crawler allows
- [ ] **P1**: CDN evaluation documented
- [ ] **P2**: `ExploreController` live with at least 1 city (Dublin)
- [ ] **P2**: Tiered restaurant display (claimed prominent, unclaimed with CTA)
- [ ] **P2**: Explore pages in sitemap
- [ ] **P3**: `LocalGuide` model with admin CRUD and approve workflow
- [ ] **P3**: At least 10 guides generated, admin-reviewed, and published
- [ ] **P3**: Public guide pages with Article + FAQPage JSON-LD
- [ ] **P4**: `/api/v2/` public endpoints live and rate-limited
- [ ] **P4**: API returns JSON-LD compatible structured data

---

# Future Directions

1. **API key management** — authenticated API clients with higher rate limits
2. **Menu knowledge graph** — pgvector + embeddings for semantic menu search
3. **EU city rollout** — systematic expansion of explore pages across Europe
4. **hreflang tags** — multilingual explore/guide pages with proper locale signals
5. **AI-first SEO architecture** — direct pipeline: DB → Structured Data → AI ingestion

---

**Created**: February 12, 2026

**Updated**: February 13, 2026

**Status**: Development-Ready — Begin Phase 1

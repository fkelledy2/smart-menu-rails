# Whiskey Ambassador — Development-Ready Specification

> **Status:** Specification complete — ready for implementation  
> **Depends on:** AI Sommelier (Phases 0–5g, complete)  
> **Target:** Restaurants with `establishment_types` containing `whiskey_bar`

---

## 1. Executive Summary

The Whiskey Ambassador is a recommendation engine for whiskey bar menus, built on the existing AI Sommelier infrastructure. It provides three guest-facing modes:

| Mode | Audience | Description |
|------|----------|-------------|
| **Quick Pick** | Newcomers | Guided 4-step quiz → 3 personalised recommendations |
| **Explore** | Enthusiasts | 2×2 flavor grid → filterable whiskey list (v2: interactive scatter map) |
| **Flight Builder** | All | AI-generated 3-whiskey tasting flights with narrative arcs |

Staff get an extended review queue with whiskey-specific fields plus CSV bulk import for bars with large collections.

---

## 2. Goals & Non-Goals

### Goals
- Help guests navigate large whiskey menus (50–200+ items) with confidence
- Serve both newcomers ("I don't know whiskey") and enthusiasts ("Show me your Islay cask-strengths")
- Curate tasting flights that tell a story and encourage exploration
- Give bar staff ownership of their whiskey data through tagging and review tools
- Activate automatically for `whiskey_bar` establishments, but require staff setup before going live

### Non-Goals
- Food pairing for whiskey (not a primary use case for whiskey bars — can be added later)
- E-commerce / bottle purchase links
- User accounts / tasting history persistence across visits (SmartMenu is sessionless)
- Cocktail recommendations (separate feature)
- Full interactive scatter-plot flavor map (deferred to v2)

---

## 3. Activation & Gating

### Auto-Detection
When a restaurant's `establishment_types` includes `whiskey_bar`, the system flags it as a Whiskey Ambassador candidate.

### Staff Confirmation
The feature is **off by default**. The restaurant owner must:
1. See a prompt in their admin dashboard: *"Your bar qualifies for the Whiskey Ambassador feature"*
2. Explicitly enable it via a new `whiskey_ambassador_enabled` boolean on `Restaurant`
3. Complete initial setup: tag at least **10 whiskey items** with region + type via the review queue or CSV import

### Guest Visibility
The "Whiskey Ambassador" button replaces the "Help me choose" Sommelier button on the SmartMenu when:
- `restaurant.whiskey_ambassador_enabled == true`
- `restaurant.whiskey_ambassador_ready?` returns true (≥10 tagged whiskeys on active menu)

### Fallback
If conditions aren't met, the standard Sommelier (spirits flow) is shown instead.

---

## 4. Data Model Changes

### 4a. Restaurant
```ruby
# Migration: add_whiskey_ambassador_to_restaurants
add_column :restaurants, :whiskey_ambassador_enabled, :boolean, default: false, null: false
add_column :restaurants, :max_whiskey_flights, :integer, default: 5, null: false
```

### 4b. Menuitem — Extended Parsed Fields
The existing `sommelier_parsed_fields` JSONB column will store whiskey-specific parsed data. New keys for whiskey items:

```json
{
  "name_raw": "Lagavulin 16yo",
  "description_raw": "Islay single malt, sherry cask finish...",
  "price": 18.0,
  "age_years": 16,
  "bottling_strength_abv": 43.0,

  "whiskey_type": "single_malt",
  "whiskey_region": "islay",
  "distillery": "Lagavulin",
  "cask_type": "sherry",
  "bottler": "OB",
  "limited_edition": false,

  "staff_tasting_note": "Rich, medicinal peat with dried fruit sweetness",
  "staff_flavor_cluster": "J",
  "staff_pick": true,
  "staff_tagged_at": "2026-01-15T10:30:00Z",
  "staff_tagged_by": 42
}
```

**No new DB columns needed** — all data lives in the existing JSONB field.

### 4c. Controlled Vocabularies

#### Whiskey Types
```ruby
WHISKEY_TYPES = %w[
  single_malt blended_malt blended_scotch
  bourbon rye tennessee
  irish_single_malt irish_single_pot irish_blended
  japanese canadian
  single_grain other
].freeze
```

#### Whiskey Regions
```ruby
WHISKEY_REGIONS = {
  # Scotch
  'islay'        => 'Islay',
  'speyside'     => 'Speyside',
  'highland'     => 'Highland',
  'lowland'      => 'Lowland',
  'campbeltown'  => 'Campbeltown',
  'islands'      => 'Islands',
  # Irish
  'ireland'      => 'Ireland',
  # American
  'kentucky'     => 'Kentucky',
  'tennessee'    => 'Tennessee',
  'american_other' => 'American (Other)',
  # Japanese
  'japan'        => 'Japan',
  # Canadian
  'canada'       => 'Canada',
  # World
  'world'        => 'World',
}.freeze
```

#### Cask Types
```ruby
CASK_TYPES = %w[
  bourbon_cask sherry_cask port_cask wine_cask rum_cask
  virgin_oak refill double_cask triple_cask other
].freeze
```

#### Flavor Clusters (Wishart-derived, simplified)
```ruby
# Simplified to 6 guest-friendly clusters from the Wishart A–J system
FLAVOR_CLUSTERS = {
  'light_delicate'  => { label: 'Light & Delicate',   grid: [0, 0], wishart: %w[G H] },
  'fruity_sweet'    => { label: 'Fruity & Sweet',     grid: [1, 0], wishart: %w[A B] },
  'rich_sherried'   => { label: 'Rich & Sherried',    grid: [1, 1], wishart: %w[C E] },
  'spicy_dry'       => { label: 'Spicy & Dry',        grid: [0, 1], wishart: %w[F] },
  'smoky_coastal'   => { label: 'Smoky & Coastal',    grid: [0, 2], wishart: %w[I] },
  'heavily_peated'  => { label: 'Heavily Peated',     grid: [1, 2], wishart: %w[J] },
}.freeze
```

### 4d. Whiskey Flights (new table)

```ruby
# Migration: create_whiskey_flights
create_table :whiskey_flights do |t|
  t.references :menu, null: false, foreign_key: true
  t.string     :theme_key, null: false        # e.g. "islay_journey", "light_to_smoky"
  t.string     :title, null: false             # "Islay Journey"
  t.text       :narrative                      # LLM-generated story text
  t.jsonb      :items, null: false, default: [] # [{menuitem_id: 1, position: 1, note: "Start here..."}]
  t.string     :source, default: 'ai'          # ai, manual
  t.string     :status, default: 'draft'       # draft, published, archived
  t.float      :total_price                    # Sum of the 3 items
  t.float      :custom_price                   # Staff override price (nil = use sum)
  t.datetime   :generated_at
  t.timestamps
end

add_index :whiskey_flights, [:menu_id, :theme_key], unique: true
add_index :whiskey_flights, :status
```

---

## 5. Service Architecture

### 5a. WhiskeyParser (new service)

**File:** `app/services/beverage_intelligence/whiskey_parser.rb`

Extracts whiskey-specific attributes from menu item text using regex patterns + keyword dictionaries. This provides the **auto-parse baseline** that staff then review and enhance.

```
Input:  Menuitem (name, description, section_name)
Output: { whiskey_type, whiskey_region, distillery, cask_type, age_years, abv, bottler, limited_edition }, confidence
```

**Key extraction rules:**
- **Distillery**: Dictionary of ~150 known distillery names (Lagavulin, Macallan, Buffalo Trace, etc.) matched against item text
- **Region**: Inferred from distillery dictionary (Lagavulin → Islay) or explicit text ("Highland single malt")
- **Type**: Keyword patterns ("single malt", "bourbon", "rye whiskey", "blended", etc.)
- **Cask type**: Keyword patterns ("sherry cask", "bourbon barrel", "port finish", "double cask", etc.)
- **Bottler**: "OB" default; "IB" if text contains independent bottler names (Gordon & MacPhail, Signatory, etc.) or "bottled by"
- **Limited edition**: Flagged if text contains "limited", "special release", "cask strength", "single cask"
- **Age/ABV**: Reuse existing `AGE_REGEX` and ABV extraction from `ExtractCandidatesJob`

**Confidence scoring:**
- Distillery match: +0.25
- Region match: +0.15
- Type match: +0.15
- Cask match: +0.1
- Age parsed: +0.1
- ABV parsed: +0.1
- Base: 0.15

### 5b. WhiskeyRecommender (new service)

**File:** `app/services/beverage_intelligence/whiskey_recommender.rb`

Handles all three recommendation modes.

#### Quick Pick Mode
```
Input:  menu, preferences: { experience_level, region_pref, flavor_pref, budget }
Output: [{menuitem, score, tags, why_text, enrichment, parsed_fields}, ...] (limit: 3)
```

**Preference flow (4 steps):**

| Step | Question | Options |
|------|----------|---------|
| 1 | Experience level | `newcomer`, `casual`, `enthusiast` |
| 2 | Region preference | `scotch`, `bourbon_rye`, `irish`, `japanese`, `surprise_me` |
| 3 | Flavor preference | `light_delicate`, `fruity_sweet`, `rich_sherried`, `spicy_dry`, `smoky_coastal`, `heavily_peated` |
| 4 | Budget | `1` (value), `2` (mid-range), `3` (premium) |

**Scoring algorithm:**

```ruby
def whiskey_preference_score(profile, parsed, experience, region_pref, flavor_pref, budget, item)
  score = 0.0

  # Region match (0.25 weight)
  item_region = parsed['whiskey_region'] || parsed['staff_region']
  if region_pref == 'surprise_me'
    score += 0.15
  elsif region_matches?(item_region, region_pref)
    score += 0.25
  end

  # Flavor cluster match (0.30 weight)
  cluster = parsed['staff_flavor_cluster'] || infer_cluster(profile)
  if cluster.present? && FLAVOR_CLUSTERS[flavor_pref]
    if cluster == flavor_pref
      score += 0.30
    elsif neighboring_cluster?(cluster, flavor_pref)
      score += 0.15
    end
  end

  # Experience-level adjustment (0.15 weight)
  case experience
  when 'newcomer'
    # Prefer approachable: lower ABV, well-known distilleries, no cask strength
    score += 0.15 if approachable?(parsed, profile)
    score -= 0.1 if challenging?(parsed, profile)
  when 'enthusiast'
    # Prefer interesting: IB, limited edition, cask strength, unusual cask
    score += 0.15 if interesting?(parsed)
    score += 0.05 if parsed['limited_edition']
  else
    score += 0.1 # casual: neutral
  end

  # Budget (0.15 weight)
  price = item.price.to_f
  if price > 0
    case budget
    when 1 then score += 0.15 if price <= 12
    when 2 then score += 0.15 if price > 10 && price <= 22
    when 3 then score += 0.15 if price > 18
    end
  end

  # Staff pick bonus
  score += 0.10 if parsed['staff_pick']

  # Baseline
  score += 0.05
  score
end
```

**"Why this suits you" text generation:**
Built from template strings referencing the matched attributes:
```
"A {region} {type} with {flavor_description}. At {age} years old, it's {experience_note}. {staff_note}"
```

#### Explore Mode
```
Input:  menu, filters: { flavor_cluster, region, type, age_range, price_range }
Output: [{menuitem, parsed_fields, flavor_cluster, enrichment}, ...] (all matching)
```

Renders whiskeys into the 2×2 flavor grid (v1) or returns filtered list.

**Grid quadrants (v1):**
```
              Light          Rich
         ┌──────────────┬──────────────┐
Sweet /  │ Light &       │ Fruity &     │
Fruity   │ Delicate      │ Sweet /      │
         │ (G, H)        │ Rich Sherried│
         │               │ (A, B, C, E) │
         ├──────────────┼──────────────┤
Dry /    │ Spicy &       │ Smoky &      │
Smoky    │ Dry           │ Coastal /    │
         │ (F)           │ Peated       │
         │               │ (I, J)       │
         └──────────────┴──────────────┘
```

Guest taps a quadrant → sees all matching whiskeys from the menu with cards showing distillery, age, region, price, flavor tags, and staff tasting note.

#### Flight Builder
```
Input:  menu
Output: [WhiskeyFlight, ...] (up to 5 flights)
```

**Generation flow:**
1. Collect all whiskey items with sufficient tagging (region + type + flavor cluster)
2. Call LLM with the list of available whiskeys and their attributes
3. LLM returns 3–5 flight suggestions, each with:
   - `theme_key` and `title`
   - 3 `menuitem_id`s with position (tasting order) and per-item note
   - Overall `narrative` text (2–3 sentences telling the story)
4. Calculate `total_price` from the 3 items
5. Save as `WhiskeyFlight` records (status: `draft` until staff publishes)

**LLM prompt contract:**
```
System: You are a whiskey expert creating tasting flights for a whiskey bar menu.
        Each flight should tell a story — a journey through flavors, regions, or styles.
        Output strict JSON.

User: {
  "menu_whiskeys": [
    {"id": 123, "name": "Lagavulin 16yo", "region": "islay", "type": "single_malt",
     "cluster": "heavily_peated", "age": 16, "cask": "sherry", "price": 18.00,
     "abv": 43.0, "tags": ["smoke_peat", "dried_fruit", "sweet"]},
    ...
  ],
  "max_flights": 5,
  "items_per_flight": 3,
  "budget_tiers": {"value": 36, "mid": 54, "premium": 75}
}

Expected output: {
  "flights": [
    {
      "theme_key": "islay_journey",
      "title": "The Islay Journey",
      "narrative": "Begin with the coastal minerality of...",
      "items": [
        {"menuitem_id": 123, "position": 1, "note": "Start with the gentle smoke..."},
        {"menuitem_id": 456, "position": 2, "note": "Now step deeper into peat..."},
        {"menuitem_id": 789, "position": 3, "note": "Finish with the full force..."}
      ]
    },
    ...
  ]
}
```

### 5c. FlightGeneratorJob (new job)

**File:** `app/jobs/menu/generate_whiskey_flights_job.rb`

Runs after the pipeline completes (or on-demand from staff dashboard). Calls LLM, saves flights.

```ruby
class Menu::GenerateWhiskeyFlightsJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 2

  def perform(menu_id)
    menu = Menu.find(menu_id)
    restaurant = menu.restaurant
    return unless restaurant.whiskey_ambassador_enabled?

    whiskey_items = menu.menuitems
      .where(sommelier_category: 'whiskey', status: 'active')
      .where("sommelier_parsed_fields->>'whiskey_region' IS NOT NULL")

    return if whiskey_items.count < 6  # Need enough variety

    # Clear old draft flights
    WhiskeyFlight.where(menu_id: menu.id, status: 'draft').destroy_all

    flights_data = llm_generate_flights(whiskey_items)
    save_flights(menu, flights_data)
  end
end
```

### 5d. Integration with Existing Pipeline

The existing pipeline chain needs one addition:

```
BeveragePipelineStartJob
  → ExtractCandidatesJob (enhanced: calls WhiskeyParser for whiskey items)
  → ResolveEntitiesJob
  → EnrichProductsJob (already uses WhiskyHunterClient for whiskey)
  → GeneratePairingsJob
  → GenerateRecsJob
  → PublishSommelierJob
  → GenerateWhiskeyFlightsJob  ← NEW (conditional: only if whiskey_bar)
```

**ExtractCandidatesJob change:**
```ruby
# After existing wine-specific deep parsing block:
if category == 'whiskey'
  whiskey_fields, whiskey_conf = whiskey_parser.parse(menuitem)
  parsed.merge!(whiskey_fields) if whiskey_fields.is_a?(Hash)
  parse_conf = [parse_conf, whiskey_conf].max
  confidence = [confidence, whiskey_conf].max
end
```

---

## 6. Staff UI

### 6a. Review Queue Enhancement

Extend `BeverageReviewQueuesController#show` to display whiskey-specific fields when the item's `sommelier_category == 'whiskey'`.

**Additional fields in the review form:**
- **Whiskey Type** — dropdown from `WHISKEY_TYPES`
- **Region** — dropdown from `WHISKEY_REGIONS`
- **Distillery** — text input (auto-suggest from known distilleries)
- **Cask Type** — dropdown from `CASK_TYPES`
- **Flavor Cluster** — dropdown from `FLAVOR_CLUSTERS` with color/description hints
- **Staff Tasting Note** — textarea (max 200 chars)
- **Staff Pick** — checkbox

All values save into `sommelier_parsed_fields` JSONB with `staff_` prefix (e.g., `staff_flavor_cluster`). Staff values take precedence over auto-parsed values.

**"Review" action update:**
```ruby
def review
  # ... existing logic ...
  if whiskey_staff_params.present?
    merged = (mi.sommelier_parsed_fields || {}).merge(whiskey_staff_params)
    merged['staff_tagged_at'] = Time.current.iso8601
    merged['staff_tagged_by'] = current_employee.id
    mi.update!(sommelier_parsed_fields: merged)
  end
end
```

### 6b. CSV Bulk Import

**New controller:** `Admin::WhiskeyImportsController`

**Route:** `POST /admin/restaurants/:restaurant_id/whiskey_imports`

**CSV format:**
```csv
menu_item_name,whiskey_type,region,distillery,cask_type,age,abv,flavor_cluster,tasting_note,staff_pick
"Lagavulin 16yo",single_malt,islay,Lagavulin,sherry,16,43.0,heavily_peated,"Rich medicinal peat with dried fruit",true
"Macallan 12 Double Cask",single_malt,speyside,Macallan,double_cask,12,40.0,rich_sherried,"Sherry sweetness with vanilla oak",false
```

**Import logic:**
1. Parse CSV with validation (known types, regions, clusters)
2. Fuzzy-match `menu_item_name` to existing `Menuitem` records (Levenshtein distance ≤ 3 or 80% token overlap)
3. Merge imported values into `sommelier_parsed_fields` with `staff_` prefix
4. Return a results summary: matched, unmatched, errors
5. Unmatched rows presented for manual mapping

**Staff UI:** Simple upload form in the restaurant admin area with a preview/confirm step before applying.

### 6c. Flight Management

Within the existing admin area, add a "Whiskey Flights" tab:

- **View** all flights (draft/published/archived), labeled with source badge: `AI` or `Manual`
- **Create Manual Flight** — form to build a flight from scratch:
  - Title (text input)
  - Select 3 whiskey items from dropdown (filtered to tagged whiskeys on current menu)
  - Set tasting order (drag or number input)
  - Write narrative text and per-item tasting notes
  - Set custom flight price (optional — defaults to sum of items)
  - Saved with `source: 'manual'`
- **Publish/Archive** toggle per flight
- **Edit** any flight (AI or manual): change narrative, items, notes, custom price
- **Regenerate** (AI flights only) — re-generate via LLM on demand
- **Set Custom Price** — staff can override the calculated total for any flight (shows savings badge to guest if lower)
- **Preview** flight as guest would see it
- **Max flights** — respects `restaurant.max_whiskey_flights` (configurable, default 5). Manual flights count toward the limit.

---

## 7. Guest UI

### 7a. Entry Point

On the SmartMenu page, if the restaurant is a qualified whiskey bar:

**Replace** the standard "Help me choose" button with a **"Whiskey Ambassador"** button (amber/gold styling).

Tapping it opens a modal/overlay with **3 tabs**:

| Tab | Icon | Label |
|-----|------|-------|
| 🎯 | Target | **Quick Pick** |
| 🗺️ | Map | **Explore** |
| 🥃 | Glass | **Flights** |

### 7b. Quick Pick Flow (Guided Quiz)

4-step flow in the existing Stimulus controller pattern:

**Step 1 — Experience Level:**
> "How familiar are you with whiskey?"
- 🌱 **Newcomer** — "I'm just getting started"
- 🥃 **Casual** — "I enjoy whiskey but haven't explored much"
- 🎓 **Enthusiast** — "I know my regions and distilleries"

**Step 2 — Region Preference:**
> "What style interests you?"
- 🏴 **Scotch** — "Scotch whisky"
- 🇺🇸 **Bourbon & Rye** — "American whiskey"
- 🇮🇪 **Irish** — "Irish whiskey"
- 🇯🇵 **Japanese** — "Japanese whisky"
- 🎲 **Surprise Me** — "Dealer's choice"

**Step 3 — Flavor Preference:**
> "What flavors appeal to you?"

Shows the 2×2 grid with descriptive labels. Guest taps one quadrant.

**Step 4 — Budget:**
> "What's your comfort zone?"
- 💰 **Value** — "Keep it reasonable"
- 💰💰 **Mid-range** — "Happy to spend a bit more"
- 💰💰💰 **Premium** — "Show me the special stuff"

**Results:** 3 recommendation cards (see §7e).

### 7c. Explore Mode

Shows the 2×2 flavor grid with counts per quadrant:

```
┌─────────────────────┬─────────────────────┐
│  Light & Delicate   │  Fruity & Sweet /   │
│  (8 whiskeys)       │  Rich & Sherried    │
│                     │  (15 whiskeys)      │
├─────────────────────┼─────────────────────┤
│  Spicy & Dry        │  Smoky & Coastal /  │
│  (6 whiskeys)       │  Heavily Peated     │
│                     │  (12 whiskeys)      │
└─────────────────────┴─────────────────────┘
```

Tapping a quadrant expands to show all matching whiskeys as cards. Optional secondary filters:
- Region (dropdown)
- Age range (slider or ≤10, 10-18, 18+)
- Price range
- **New** toggle — show only items added to menu in last 14 days
- **Rare** toggle — show only items tagged `limited_edition: true` or staff-tagged as rare

### 7d. Flights Tab

Shows published flights as horizontal-scrollable cards:

```
┌──────────────────────────────┐
│  🥃 The Islay Journey        │
│  "From gentle smoke to       │
│   full peat storm"           │
│                              │
│  1. Bowmore 12  ─  €12      │
│  2. Caol Ila 12 ─  €14      │
│  3. Lagavulin 16 ─ €18      │
│                              │
│  Flight: €40  (save €4)      │  ← custom_price if set
│  Per dram: €13.33            │  ← total / 3
│  ────────────────────────    │
│  [View Details]              │
└──────────────────────────────┘
```

**Pricing logic:**
- `display_price` = `custom_price` if set by staff, otherwise `total_price` (sum of items)
- `per_dram` = `display_price / items.count`
- If `custom_price < total_price`, show savings: "(save €X)"

Expanding "View Details" shows the full narrative + per-item tasting notes.

### 7e. Whiskey Card Component

Each recommendation card displays:

```
┌──────────────────────────────────┐
│  ★ Staff Pick  🆕 New  💎 Rare   │  (badges, if applicable)
│  Lagavulin 16 Year Old           │
│  Islay · Single Malt · 43% ABV  │
│  Sherry Cask                     │
│                                  │
│  🏷️ smoke_peat · dried_fruit ·  │
│     sweet                        │
│                                  │
│  "Rich, medicinal peat with     │
│   dried fruit sweetness"         │
│   — Bar team                     │
│                                  │
│  💰 €18.00                       │
│                                  │
│  Why this suits you:             │
│  "An Islay classic with bold     │
│   peat and sherry sweetness.     │
│   At 16 years, it's complex      │
│   but not overwhelming."         │
│                                  │
│  [Add to My Picks]               │
└──────────────────────────────────┘
```

**Badge logic:**
- **★ Staff Pick** — shown if `staff_pick == true`
- **🆕 New** — shown if menuitem `created_at` is within last 14 days
- **💎 Rare** — shown if `limited_edition == true` or staff-tagged rare

---

## 8. API Endpoints

### 8a. Guest-Facing

```ruby
# config/routes.rb additions
post 'sommelier/recommend_whiskey', to: 'sommelier#recommend_whiskey'
get  'sommelier/explore_whiskeys',  to: 'sommelier#explore_whiskeys'
get  'sommelier/whiskey_flights',   to: 'sommelier#whiskey_flights'
```

**POST `/sommelier/recommend_whiskey`**
```json
// Request
{
  "menu_id": 9,
  "preferences": {
    "experience_level": "newcomer",
    "region_pref": "scotch",
    "flavor_pref": "rich_sherried",
    "budget": 2
  }
}

// Response
{
  "recommendations": [
    {
      "menuitem_id": 123,
      "name": "Lagavulin 16yo",
      "price": 18.0,
      "whiskey_type": "single_malt",
      "region": "islay",
      "distillery": "Lagavulin",
      "cask_type": "sherry",
      "age_years": 16,
      "abv": 43.0,
      "flavor_cluster": "heavily_peated",
      "tags": ["smoke_peat", "dried_fruit", "sweet"],
      "staff_tasting_note": "Rich, medicinal peat with dried fruit sweetness",
      "staff_pick": true,
      "why_text": "An Islay classic with bold peat and sherry sweetness...",
      "score": 0.85
    },
    ...
  ]
}
```

**GET `/sommelier/explore_whiskeys?menu_id=9&cluster=rich_sherried&region=speyside`**
```json
// Response
{
  "quadrants": {
    "light_sweet": { "label": "Light & Delicate", "count": 8 },
    "rich_sweet": { "label": "Fruity & Sweet / Rich Sherried", "count": 15 },
    "light_dry": { "label": "Spicy & Dry", "count": 6 },
    "rich_dry": { "label": "Smoky & Peated", "count": 12 }
  },
  "items": [
    {
      "menuitem_id": 456,
      "name": "Macallan 12 Double Cask",
      "price": 14.0,
      "whiskey_type": "single_malt",
      "region": "speyside",
      "distillery": "Macallan",
      "age_years": 12,
      "flavor_cluster": "rich_sherried",
      "tags": ["vanilla_oak", "dried_fruit", "sweet"],
      "staff_tasting_note": "Sherry sweetness with vanilla oak"
    },
    ...
  ]
}
```

**GET `/sommelier/whiskey_flights?menu_id=9`**
```json
// Response
{
  "flights": [
    {
      "id": 1,
      "theme_key": "islay_journey",
      "title": "The Islay Journey",
      "narrative": "Begin with the coastal minerality of...",
      "total_price": 44.0,
      "items": [
        { "menuitem_id": 123, "name": "Bowmore 12", "price": 12.0, "position": 1, "note": "Start with gentle smoke..." },
        { "menuitem_id": 456, "name": "Caol Ila 12", "price": 14.0, "position": 2, "note": "Step deeper into peat..." },
        { "menuitem_id": 789, "name": "Lagavulin 16", "price": 18.0, "position": 3, "note": "Full force of Islay..." }
      ]
    },
    ...
  ]
}
```

### 8b. Staff-Facing

```ruby
# Staff review (existing route, enhanced)
patch 'beverage_review_queues/:id/review', to: 'beverage_review_queues#review'

# CSV import (new)
post 'admin/restaurants/:restaurant_id/whiskey_imports', to: 'admin/whiskey_imports#create'

# Flight management (new) — supports both AI-generated and manually created flights
namespace :admin do
  resources :whiskey_flights, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      post :publish
      post :archive
      post :regenerate  # AI-only: re-generate narrative + items via LLM
    end
  end
end
```

---

## 9. Frontend (Stimulus Controller)

### 9a. Controller Structure

**File:** `app/javascript/controllers/whiskey_ambassador_controller.js`

New Stimulus controller (separate from `sommelier_controller.js` to avoid complexity bloat).

**Targets:**
```javascript
static targets = [
  "tabBar", "quickPickPanel", "explorePanel", "flightsPanel",
  "step", "optionBtn", "results", "grid", "flightList",
  "filterRegion", "filterAge", "filterPrice",
  "myPicksPanel", "myPicksList"
]
```

**Values:**
```javascript
static values = {
  menuId: Number,
  currentTab: { type: String, default: "quickpick" },
  currentStep: { type: Number, default: 0 },
  preferences: { type: Object, default: {} },
}
```

**Key methods:**
- `selectTab(tab)` — switch between Quick Pick / Explore / Flights
- `selectOption(event)` — capture preference at each step
- `nextStep()` / `prevStep()` — step navigation
- `fetchRecommendations()` — POST to `/sommelier/recommend_whiskey`
- `fetchExploreData()` — GET to `/sommelier/explore_whiskeys`
- `fetchFlights()` — GET to `/sommelier/whiskey_flights`
- `selectQuadrant(event)` — filter explore view by cluster
- `buildWhiskeyCard(item)` — render a whiskey card
- `buildFlightCard(flight)` — render a flight card
- `addToMyPicks(event)` — save item to sessionStorage + update "My Picks" panel
- `removeFromMyPicks(event)` — remove item from session picks
- `renderMyPicks()` — re-render the "My Picks" mini-list

### 9d. Session Memory & "My Picks"

**Storage:** `sessionStorage` (key: `wa_picks_${menuId}`, value: JSON array of `{menuitem_id, name, price}`)

**Behavior:**
- Each whiskey card has an **"Add to My Picks"** button
- When a guest adds an item, it's saved to `sessionStorage` and a persistent **"My Picks"** mini-panel appears at the bottom of the Ambassador overlay
- The mini-panel shows a compact list of picked whiskeys with name + price, plus a total
- On Quick Pick re-runs, previously recommended `menuitem_id`s (from sessionStorage) are sent in the request body as `exclude_ids` — the recommender deprioritizes (score −0.15) but doesn't exclude them entirely
- "My Picks" persists across tab switches (Quick Pick → Explore → Flights) but clears on page reload (sessionStorage lifecycle)
- "Try Again" button on results screen pre-fills the previous step selections

**My Picks mini-panel wireframe:**
```
┌──────────────────────────────────┐
│  📋 My Picks (3)                 │
│  ├─ Lagavulin 16yo     €18.00   │
│  ├─ Macallan 12 DC     €14.00   │
│  └─ Redbreast 12       €12.00   │
│                                  │
│  Total: €44.00                   │
└──────────────────────────────────┘
```

### 9b. Partial

**File:** `app/views/smartmenus/_whiskey_ambassador.html.erb`

Rendered conditionally in `show.html.erb` when whiskey ambassador is active.

```erb
<div data-controller="whiskey-ambassador"
     data-whiskey-ambassador-menu-id-value="<%= @smartmenu.menu_id %>">

  <!-- Tab bar -->
  <div class="wa-tabs" data-whiskey-ambassador-target="tabBar">
    <button data-action="click->whiskey-ambassador#selectTab"
            data-tab="quickpick" class="wa-tab active">🎯 Quick Pick</button>
    <button data-action="click->whiskey-ambassador#selectTab"
            data-tab="explore" class="wa-tab">🗺️ Explore</button>
    <button data-action="click->whiskey-ambassador#selectTab"
            data-tab="flights" class="wa-tab">🥃 Flights</button>
  </div>

  <!-- Quick Pick panel (steps 0-3 + results) -->
  <!-- Explore panel (grid + filter + list) -->
  <!-- Flights panel (flight cards) -->
</div>
```

### 9c. CSS

**File:** `app/assets/stylesheets/components/_whiskey_ambassador.scss`

Amber/gold color scheme to differentiate from the sommelier's purple/wine tones:
```scss
$wa-gold: #C98D35;
$wa-dark: #2C1810;
$wa-warm: #F5E6D0;

.wa-tabs { ... }
.wa-tab { ... }
.wa-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.wa-quadrant { ... }
.wa-card { border-left: 3px solid $wa-gold; ... }
.wa-flight-card { ... }
.wa-staff-pick { ... }
.wa-narrative { font-style: italic; ... }
```

---

## 10. Implementation Phases

### Phase W1: Data Foundation (est. 2 days)
- [ ] Migration: `whiskey_ambassador_enabled` + `max_whiskey_flights` on `restaurants`
- [ ] Migration: `create_whiskey_flights` table (with `source`, `custom_price` columns)
- [ ] `WhiskeyParser` service with distillery dictionary, region inference, type/cask extraction
- [ ] Tests for WhiskeyParser (12+ test cases)
- [ ] Integrate WhiskeyParser into `ExtractCandidatesJob` (parallel to WineParser block)

### Phase W2: Staff Tagging (est. 2 days)
- [ ] Extend `BeverageReviewQueuesController` with whiskey fields
- [ ] Update review queue view with whiskey-specific form fields
- [ ] `Admin::WhiskeyImportsController` with CSV parsing + fuzzy matching
- [ ] CSV import view (upload → preview → confirm)
- [ ] Tests for CSV import (valid, invalid, fuzzy matching)

### Phase W3: Recommender (est. 2 days)
- [ ] `WhiskeyRecommender` service (Quick Pick scoring + Explore filtering)
- [ ] `SommelierController#recommend_whiskey` action
- [ ] `SommelierController#explore_whiskeys` action
- [ ] "Why this suits you" text generation templates
- [ ] Tests for recommender (15+ test cases across experience levels, regions, clusters)

### Phase W4: Flight Builder (est. 3 days)
- [ ] `WhiskeyFlight` model with validations (`source` enum: ai/manual, `custom_price`, `display_price` helper)
- [ ] `GenerateWhiskeyFlightsJob` with LLM prompt (respects `max_whiskey_flights`)
- [ ] `SommelierController#whiskey_flights` action (includes per-dram pricing + savings badge)
- [ ] `Admin::WhiskeyFlightsController` (full CRUD + publish/archive/regenerate + manual create form)
- [ ] Manual flight creation: item picker dropdown, tasting order, custom price, narrative editor
- [ ] Tests for flight generation, manual creation, pricing logic, and management

### Phase W5: Guest UI (est. 3 days)
- [ ] `whiskey_ambassador_controller.js` Stimulus controller (tabs, quiz, explore grid, flights)
- [ ] Session memory: `sessionStorage` for "My Picks" list + deprioritize already-shown items on re-runs
- [ ] "My Picks" persistent mini-panel with add/remove/total
- [ ] "Try Again" button with pre-filled previous preferences
- [ ] Badge rendering: ★ Staff Pick, 🆕 New (≤14 days), 💎 Rare (limited_edition)
- [ ] `_whiskey_ambassador.html.erb` partial with all three panels + My Picks panel
- [ ] `_whiskey_ambassador.scss` styling (amber/gold theme + badges + My Picks)
- [ ] Conditional rendering in `show.html.erb` (ambassador vs sommelier)
- [ ] `Restaurant#whiskey_ambassador_ready?` helper method
- [ ] Routes for all new endpoints

### Phase W6: Activation & Polish (est. 1 day)
- [ ] Admin dashboard prompt for whiskey bar restaurants
- [ ] Setup wizard / checklist (enable → tag 10 items → publish flights → go live)
- [ ] Fallback to standard sommelier when not ready
- [ ] E2E test on a whiskey bar menu

### Phase W7: v2 Enhancements (future)
- [ ] Interactive scatter-plot flavor map (Canvas/SVG)
- [ ] "If you liked X, try Y" — similarity-based exploration
- [ ] Whiskey of the day / seasonal highlights
- [ ] Food pairing suggestions for whiskey
- [ ] Guest cross-visit history (requires user accounts — out of scope for sessionless SmartMenu)

**Total estimated effort: ~13 dev days (W1–W6)**

---

## 11. File Inventory

| Phase | File | Action |
|-------|------|--------|
| W1 | `db/migrate/xxx_add_whiskey_ambassador_to_restaurants.rb` | Create |
| W1 | `db/migrate/xxx_create_whiskey_flights.rb` | Create |
| W1 | `app/services/beverage_intelligence/whiskey_parser.rb` | Create |
| W1 | `app/jobs/menu/extract_candidates_job.rb` | Modify |
| W2 | `app/controllers/beverage_review_queues_controller.rb` | Modify |
| W2 | `app/views/beverage_review_queues/show.html.erb` | Modify |
| W2 | `app/controllers/admin/whiskey_imports_controller.rb` | Create |
| W2 | `app/views/admin/whiskey_imports/new.html.erb` | Create |
| W3 | `app/services/beverage_intelligence/whiskey_recommender.rb` | Create |
| W3 | `app/controllers/sommelier_controller.rb` | Modify |
| W4 | `app/models/whiskey_flight.rb` | Create |
| W4 | `app/jobs/menu/generate_whiskey_flights_job.rb` | Create |
| W4 | `app/controllers/admin/whiskey_flights_controller.rb` | Create |
| W5 | `app/javascript/controllers/whiskey_ambassador_controller.js` | Create |
| W5 | `app/views/smartmenus/_whiskey_ambassador.html.erb` | Create |
| W5 | `app/assets/stylesheets/components/_whiskey_ambassador.scss` | Create |
| W5 | `app/views/smartmenus/show.html.erb` | Modify |
| W5 | `app/models/restaurant.rb` | Modify |
| W5 | `config/routes.rb` | Modify |
| W6 | `app/views/admin/restaurants/show.html.erb` (or equivalent) | Modify |
| Tests | `test/services/beverage_intelligence/whiskey_parser_test.rb` | Create |
| Tests | `test/services/beverage_intelligence/whiskey_recommender_test.rb` | Create |
| Tests | `test/controllers/admin/whiskey_imports_controller_test.rb` | Create |
| Tests | `test/models/whiskey_flight_test.rb` | Create |
| Tests | `test/jobs/menu/generate_whiskey_flights_job_test.rb` | Create |

---

## 12. Acceptance Criteria

### Guest Experience
- [ ] Guest at a whiskey bar sees "Whiskey Ambassador" button (not generic sommelier)
- [ ] Quick Pick: 4-step flow returns 3 personalised whiskey recommendations
- [ ] Each recommendation card shows distillery, region, age, ABV, cask, tags, staff note, price, and "why this suits you"
- [ ] Cards display badges: ★ Staff Pick, 🆕 New (≤14 days), 💎 Rare (limited_edition)
- [ ] Explore: 2×2 flavor grid shows count per quadrant; tapping reveals matching whiskeys
- [ ] Explore: secondary filters (region, age, price, New, Rare) narrow results
- [ ] Flights: at least 2 published flights visible with narrative, 3 items each, total price, per-dram price
- [ ] Flights show savings badge when staff sets a custom price below sum-of-items
- [ ] Flight detail view shows per-item tasting notes and tasting order
- [ ] "My Picks" mini-panel persists across tabs; shows picked whiskeys + total price
- [ ] "Try Again" on results pre-fills previous preferences and deprioritizes already-shown items

### Staff Experience
- [ ] Review queue shows whiskey-specific fields for whiskey items
- [ ] Staff can set region, type, cask, cluster, tasting note, staff pick per item
- [ ] CSV import matches ≥80% of rows to existing menu items (on representative test data)
- [ ] Flight management: staff can publish, archive, edit, regenerate AI flights
- [ ] Staff can create manual flights from scratch (pick items, write narrative, set custom price)
- [ ] Staff can override flight price (custom_price) for any flight (AI or manual)
- [ ] Max flights configurable per restaurant (default: 5, range: 2–10)
- [ ] Setup checklist visible in admin when `whiskey_bar` detected

### System Behavior
- [ ] Feature auto-detected for `whiskey_bar` establishments
- [ ] Feature gated behind `whiskey_ambassador_enabled` + ≥10 tagged items
- [ ] Falls back to standard sommelier when not ready
- [ ] Pipeline integrates WhiskeyParser without breaking existing wine/spirits flows
- [ ] Flight generation uses LLM and costs < $0.05 per menu regeneration
- [ ] All new services have ≥90% test coverage

---

## 13. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| WhiskyHunter API unreliable/deprecated | Medium | LLM fallback already exists; staff tagging reduces API dependency |
| LLM flight generation hallucinations | High | Validate all `menuitem_id`s against actual menu before saving |
| Small whiskey menus (<10 items) | Low | Disable flights; show explore mode only; lower tag threshold |
| Staff won't tag whiskeys | High | Auto-parse baseline is usable; CSV import reduces effort; show value via setup wizard |
| Flavor cluster assignment subjectivity | Medium | Provide clear descriptions + examples per cluster; staff override always wins |
| Distillery dictionary incomplete | Low | LLM fallback for unknown distilleries; dictionary grows over time |

---

## 14. Resolved Design Decisions

All open questions have been discussed and resolved:

| # | Question | Decision | Spec Impact |
|---|----------|----------|-------------|
| 1 | Flight pricing display | **Total + Per-Dram + Staff Override** — show total, per-dram, and savings badge if custom_price < sum | §4d `custom_price` column, §6c custom price UI, §7d pricing logic, §12 acceptance criteria |
| 2 | New Arrivals / Rare Finds | **Badges + Filter** — 🆕 New (≤14 days) and 💎 Rare (limited_edition) badges on cards + filter toggles in Explore mode | §7c filter toggles, §7e badge logic, §12 acceptance criteria |
| 3 | Session memory | **Session Memory + History** — `sessionStorage` tracks shown items + "My Picks" mini-panel with add/remove/total | §9d new section, §9a targets, §W5 phase tasks, §12 acceptance criteria |
| 4 | Max flights per menu | **Configurable (default 5)** — `max_whiskey_flights` setting on Restaurant (range: 2–10) | §4a migration, §6c max flights, §12 acceptance criteria |
| 5 | Manual flight creation | **Yes — Full Manual Create** — staff can build flights from scratch alongside AI-generated ones, using same WhiskeyFlight model with `source: 'manual'` | §4d `source` column, §6c manual create form, §8b routes (new/create), §W4 phase tasks, §12 acceptance criteria |

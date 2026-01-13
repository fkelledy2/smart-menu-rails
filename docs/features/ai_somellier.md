# AI Sommelier (Whiskey + Wine) Feature Plan

## Summary
This document proposes a production-ready **AI Sommelier** for Mellow.menu that is triggered by **initial menu OCR import** and then runs a **Beverage Intelligence Pipeline**:

- Detect beverages from OCR text (whiskey/spirits/wine/etc)
- Parse structured attributes from noisy text
- Resolve each OCR line to a canonical product entity
- Enrich products from external sources (with attribution + caching)
- Generate:
  - Food pairings against this venue’s menu
  - "If you like X you’ll love Y" similarity recommendations
- Publish results into guest UI + internal review queue

The architecture is designed so the **same pipeline works for whiskey and wine**, with wine-specific parsing rules and pairing heuristics layered on top.

---

## Goals
- Provide a guest-facing **“Help me choose a whiskey/wine”** flow that does not require typing and feels “premium”.
- Make enrichment and recommendations **reliable and auditable** (attribution, confidence, staff override/lock).
- Keep OCR ingestion fast; move heavy lifting into **Sidekiq async jobs**.
- Support gradual rollout:
  - Rules-only MVP
  - LLM fallback for ambiguity
  - Vector similarity as an enhancement

## Non-goals (initially)
- Real-time per-request external API lookups (we use cached enrichment + scheduled refresh)
- Perfect global catalog coverage (we support unresolved + staff review + incremental improvements)
- Free-form chatbot (we use a structured, tap-driven flow)

---

## Trigger + orchestration

### Event
`MenuImported(menu_id, restaurant_id, raw_ocr_text, ocr_items[])`

**Trigger point**: after OCR import creates `OcrMenuImport`/sections/items and a `Menu` is created/updated.

### Sidekiq orchestration (job chain)
1. `Menu::ExtractCandidatesJob(menu_id)`
2. `Menu::ResolveEntitiesJob(menu_id)`
3. `Menu::EnrichProductsJob(menu_id)`
4. `Menu::GeneratePairingsJob(menu_id)`
5. `Menu::GenerateRecsJob(menu_id)`
6. `Menu::PublishSommelierJob(menu_id)`

**Principle**: each job is idempotent, safe to retry, and writes its own progress marker.

### Failure & retry strategy
- Each job:
  - uses Sidekiq retry with exponential backoff
  - writes structured logs + job metadata for debugging
  - records failures in a pipeline run record (see data model)
- External API calls:
  - cached by external ID
  - circuit breaker: if rate-limited/5xx spikes, pause external enrichment and proceed with fallback recommendations

---

## Detection + classification (whiskey/wine/etc)

### Categories
For each OCR line/block/row, classify into:
- `whisky/whiskey`
- `wine`
- `other_spirit` (rum, gin, tequila…)
- `cocktail`
- `beer`
- `non_alcoholic`
- `food`

### Approach
1. **Rules + dictionary (fast path)**
   - Keywords: “single malt”, “blended”, “bourbon”, “rye”, “Speyside”, “Islay”, “12yo”, “cask”, “NAS”, “BIB”, etc.
   - Wine hints: grape/appellation patterns, “DOC/DOP”, “Riserva”, “2018”, “Glass/Bottle”, “750ml”.
2. **LLM classifier fallback (slow path)**
   - Only run when:
     - rules confidence below threshold, or
     - line looks like a beverage but category ambiguous

### Persisted outputs
For each classified line:
- `category`
- `classification_confidence`
- `classifier_version` (rules version or prompt version)

---

## Parsing (structured fields from noisy OCR)
Parsing is critical for entity resolution and later explainability.

### Parsed fields (shared)
- `name_raw` (original text)
- `producer` / `distillery` / `brand` (if present)
- `expression` (e.g., “12”, “DoubleWood”, “PX Cask”)
- `age_years`
- `vintage_year` (wine-heavy)
- `bottling_strength_abv`
- `size_ml` (if present)
- `serve_type` (neat/flight/25ml/35ml/50ml/glass/bottle)
- `price`

### Persisted outputs
- `parsed_fields_json`
- `parse_confidence`
- `parser_version`

### Strategy
- Rules-first parsing with regex and known patterns.
- LLM parser fallback only for:
  - multi-line/oddly formatted entries
  - combined “name + vintage + region + price” blobs

---

## Entity resolution (OCR → canonical product)

### Candidate generation
Generate query strings based on parsed fields, e.g.
- `"Redbreast 12 Irish whiskey"`
- `"Ardbeg Uigeadail Islay single malt"`

Then retrieve top-N candidates from:
- internal catalog (if already enriched)
- external sources (see enrichment sources)

### Candidate scoring
Score candidates by:
- text similarity (token/trigram/synonyms)
- field consistency (age, ABV, region/category)
- venue context boost (configurable; e.g. Ireland → Irish whiskey)
- uniqueness margin (if a clear winner exists)

### Outputs per menu item
- `resolved_product_id` or `unresolved`
- `resolution_confidence`
- `resolution_explanations` (stored, used in staff review UI)
- `locked` (manual override prevents future auto-rewrite)

---

## External enrichment

### Sources (pragmatic initial)
- Whisky Hunter API
- WHISKY:EDITION API

Wine enrichment options will likely differ (producer/grape/appellation databases). The pipeline supports multiple sources with per-field attribution.

### Enrichment payload (persisted)
Store in DB (JSON payload + normalized top-level columns as needed):
- `category` (single malt, bourbon, rye…)
- `country/region` (Islay, Speyside…)
- `brand_story` (short, menu-friendly)
- `production_notes` (cask types, peat, maturation)
- `tasting_notes` (nose/palate/finish)
- `abv`, `age`, `cask_finish`, `chill_filtered?`, `natural_colour?` (when available)
- `image_url` (optional)
- `source_attribution` per field

### Caching policy
- Cache by `(source, external_id)`.
- Refresh schedule:
  - whiskey: monthly (low change)
  - market/auction fields (if used): weekly
- Store:
  - `fetched_at`
  - `expires_at`
  - `etag`/`last_modified` if supported

---

## Flavor profiles (shared representation for whiskey + wine + food)

### Controlled vocabulary
Define a controlled set of tags to keep consistency:

**Flavor tags (examples)**
- sweet
- smoke_peat
- spice
- vanilla_oak
- dried_fruit
- citrus
- floral
- nutty
- saline
- umami
- bitter
- creamy
- tannic (wine)

**Structural tags / metrics**
- alcohol_intensity (0-1)
- body (0-1)
- sweetness_level (0-1)
- finish_length (0-1)
- peat_level (0-1) (whiskey)
- acidity (0-1) (wine)
- tannin (0-1) (wine)

### Generation approach
- Convert drink tasting notes → tags via LLM using controlled vocabulary.
- Convert each food menu item → tags using dish name/description/ingredients.

Persist:
- tags array
- structure metrics JSON
- provenance metadata (prompt version / model version)

---

## Pairing generation (food ↔ whiskey/wine)

### Scoring
For each candidate pairing:
- complement score
- contrast score
- risk flags

### Outputs
- “Pairs well with” (top 3)
- “Surprising match” (top 1)
- “Avoid with” (optional)

### Notes
- Pairing rules are shared, but:
  - whiskey emphasizes smoke/char, sweetness vs dessert/cheese, ABV vs fat
  - wine emphasizes acidity/tannin/body vs richness/salt/spice/sweetness

---

## Similarity recommendations (“If you like X, you’ll love Y”)

### Engine
Use embeddings + `pgvector` for nearest-neighbor search.

- Construct a canonical “tasting profile text” per product:
  - region, cask type, peat level, tasting notes, style descriptors
- Generate embedding
- Store in DB

### Business filters
- Prefer recommendations that are on-menu (venue stocks)
- Price-tier logic (avoid big jumps by default)
- Diversity constraints (avoid 5 near-identical Islays)

### Outputs
- recommended product + score
- rationale (short explainable text)

---

## Guest UI flow (tap-driven, no typing)

### Entry points
- “Help me choose a whiskey” button within the whiskey section
- Context prompt after tapping a whiskey

### Flow
1. Preference capture (3 taps)
   - Smoky / Not smoky
   - Sweet / Dry / Spicy
   - Budget: € / €€ / €€€
2. Recommend 3 pours
   - each card: one-line story, 3 tags, best pairing on this menu
3. Refinement
   - “More like #1 (smokier)” / “More like #2 (sweeter)” / “Surprise me”
4. Explainability (optional)
   - “Why this?” expands: cask/region/key notes/pairing logic

---

## Staff review + overrides (operational must-have)

### Review queue
- Unresolved items
- Low-confidence resolutions
- Conflicts (multiple close candidates)

### Actions
- Approve selected resolution
- Search and choose alternative
- Override enrichment fields
- Lock resolution (prevents future auto changes)

### Auditability
- Store:
  - who changed what and when
  - original auto decision + explanation
  - manual override rationale (optional)

---

## Data model (Rails-friendly)
This follows the shape described in the concept, with a few operational additions.

### Core tables
- `Menu` has_many `menu_items`

- `MenuItem`
  - `raw_text`
  - `category`
  - `price`
  - `parsed_fields_json`
  - `classification_confidence`
  - `parse_confidence`

- `Product` (canonical bottle / wine)
  - `product_type` (whiskey/wine/other)
  - `canonical_name`
  - `attributes_json`

- `MenuItemProductLink`
  - `menu_item_id`
  - `product_id`
  - `resolution_confidence`
  - `explanations`
  - `locked` boolean

- `ProductEnrichment`
  - `product_id`
  - `source`
  - `external_id`
  - `payload_json`
  - `fetched_at`
  - `expires_at`

- `FlavorProfile`
  - polymorphic `profilable` (Product or MenuItem)
  - `tags` (array)
  - `structure_metrics_json`
  - `embedding_vector` (pgvector)

- `PairingRecommendation`
  - `drink_menu_item_id`
  - `food_menu_item_id`
  - `score`
  - `rationale`
  - `risk_flags_json`

- `SimilarProductRecommendation`
  - `product_id`
  - `recommended_product_id`
  - `score`
  - `rationale`

### Operational table (recommended)
- `BeveragePipelineRun`
  - `menu_id`
  - `status` (running/succeeded/failed/partial)
  - `started_at`, `completed_at`
  - `current_step`
  - `error_summary`
  - counters (items_processed, unresolved_count, low_confidence_count)

---

## Service boundaries (recommended Rails structure)
- `BeverageIntelligence::Classifier`
- `BeverageIntelligence::Parser`
- `BeverageIntelligence::EntityResolver`
- `BeverageIntelligence::EnrichmentClient::*`
- `BeverageIntelligence::FlavorProfiler`
- `BeverageIntelligence::PairingEngine`
- `BeverageIntelligence::Recommender` (vector + business filters)

---

## Prompt contracts (LLM usage, consistent + cheap)
LLM calls should be:
- rare (only when rules cannot decide)
- deterministic (structured JSON output)
- versioned (store prompt version)

### 1) Classification prompt contract
Input:
- `raw_text`
- optional `nearby_lines` context
Output JSON:
- `category` (enum)
- `confidence` (0-1)
- `signals` (array of strings)

### 2) Parsing prompt contract
Input:
- `raw_text`
- `category`
Output JSON:
- `producer`
- `expression`
- `age_years`
- `vintage_year`
- `abv`
- `size_ml`
- `serve_type`
- `price`
- `confidence`

### 3) Flavor tagging prompt contract
Input:
- `canonical_description` (tasting notes/story)
Output JSON:
- `tags` (must be from controlled vocab)
- `structure_metrics` (0-1 values)
- `confidence`

---

## Rollout phases

### Phase 0: Foundations (1-2 weeks)
- [ ] Add data model tables (minimal columns + JSON where needed)
- [ ] Implement `MenuImported` trigger + `BeveragePipelineRun`
- [ ] Implement `ExtractCandidatesJob` with rules-only classifier/parser
- [ ] Admin-only “pipeline status” page

### Phase 1: Entity resolution MVP (2-3 weeks)
- [ ] Implement `ResolveEntitiesJob`
- [ ] Create staff review queue UI for unresolved/low-confidence
- [ ] Manual override + lock

### Phase 2: Enrichment (2-3 weeks)
- [ ] Implement `EnrichProductsJob` with caching + attribution
- [ ] Scheduled refresh job

### Phase 3: Pairings (2-4 weeks)
- [ ] Flavor profiles for drinks + food items
- [ ] Pairing engine + `PairingRecommendation`
- [ ] Guest UI surfacing: “Best with …”

### Phase 4: Similarity recs (2-4 weeks)
- [ ] pgvector embeddings for products
- [ ] On-menu similarity recommendations
- [ ] Guest UI “If you like …” cards

### Phase 5: Wine enhancements (2-4 weeks)
- [ ] Better wine parsing (vintage/grape/appellation)
- [ ] Wine pairing heuristics
- [ ] Wine UI entry point

---

## Acceptance criteria
- [ ] Pipeline runs automatically after menu OCR import and does not block menu creation.
- [ ] Each beverage line has:
  - [ ] category + confidence
  - [ ] parsed fields JSON + confidence
  - [ ] resolution to a canonical `Product` when possible
- [ ] Low-confidence/unresolved items appear in a staff review queue.
- [ ] Staff can override and lock resolutions.
- [ ] Enrichment is cached, attributed, and refreshable.
- [ ] Guest UI can recommend 3 pours based on 3-tap preference capture.
- [ ] Recommendations include at least one pairing suggestion from the current menu.

---

## Open questions
- What is the authoritative “menu OCR import completed” hook/event in the current codebase (model callback vs service vs controller action)?
- Do we want a global cross-venue product catalog immediately, or start per-venue and merge later?
- Which LLM provider/cost constraints should shape prompt design (token limits, latency targets)?

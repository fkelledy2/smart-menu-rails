# Nearby Menus Map

## Status
- Priority Rank: #32
- Category: Post-Launch
- Effort: L
- Dependencies: Restaurant geocoding data (new), map provider API key (Google Maps or Mapbox), SmartMenu public menu URLs already exist

## Problem Statement
Potential customers who don't already know about mellow.menu-powered restaurants have no discovery surface. A map-based discovery page at `mellow.menu/discover` (or equivalent) lets diners find restaurants near them, preview their menus, and link directly into the SmartMenu experience. This creates an organic, consumer-facing acquisition channel and gives mellow.menu a public proof point of its restaurant network size.

## Success Criteria
- A visitor to the mellow.menu discovery page can see restaurants near their location plotted on a map
- Clicking a restaurant marker shows a popup with basic restaurant details and a link to their SmartMenu
- Restaurants can opt in or out of appearing on the map from their restaurant settings
- The page loads in under 2 seconds on a 4G mobile connection
- Restaurant owners can see how many users clicked through to their SmartMenu from the discovery map

## User Stories
- As a potential diner, I want to see which nearby restaurants use mellow.menu so I can explore their menus before deciding where to eat.
- As a restaurant owner, I want my restaurant to appear on the discovery map to attract new customers who aren't already aware of me.
- As a restaurant owner, I want to opt out of appearing on the map if I prefer not to be publicly discoverable on the platform.
- As a mellow.menu marketing manager, I want to feature selected restaurants on the map to support launch campaigns in new cities.

## Functional Requirements
1. A publicly accessible discovery page at `/discover` renders an interactive map with markers for each opted-in restaurant.
2. Restaurant data for the map is served from a JSON endpoint (`/api/v1/restaurants/nearby` or a dedicated map controller action) with results filtered by bounding box from the map viewport — not a full dataset dump.
3. Each marker, when clicked, opens a popup showing: restaurant name, cuisine tags (if set), price range indicator, a thumbnail image (if available), and a "View Menu" link to their SmartMenu URL.
4. A "Use my location" button requests browser geolocation and recentres the map.
5. A text-based location search (geocoding) allows searching without geolocation.
6. Restaurants opt in to map visibility via a toggle in their restaurant settings ("Appear on mellow.menu discover map"). Default: opt-in for new restaurants.
7. A `map_featured` flag (admin-only) allows the mellow.menu team to highlight specific restaurants with a distinct marker style.
8. Basic click-through analytics: when a visitor clicks "View Menu" from a map popup, an event is recorded. Restaurant owners can see a "Discover Map views" count in their analytics dashboard.
9. The map respects the `robots.txt` and is indexable for SEO.
10. Markers cluster automatically at low zoom levels to prevent overcrowding.

## Non-Functional Requirements
- Frontend: the map component is rendered via a Stimulus controller wrapping the map provider's JS SDK — no React, no separate JS framework. The map JS is loaded lazily (dynamic import) to avoid blocking page load.
- The `/discover` page must load its static shell in under 1 second; map tiles and restaurant data load asynchronously.
- Database: use PostGIS `ST_DWithin` for bounding-box queries, OR use the existing pgvector extension with a precomputed `point` column — evaluate which is already available in the production schema before choosing. If PostGIS is not enabled, a bounding-box approximation using plain latitude/longitude comparisons is acceptable for v1 given the query volumes expected.
- Analytics events are written to a lightweight `MapAnalytic` model asynchronously via a Sidekiq job — never blocking the API response.
- Restaurant location data (lat/lng) is derived from their address via a geocoding job run once on opt-in, not on every page load.
- Map API keys must be environment variables, never hardcoded. Restrict the browser key to the mellow.menu domain in the provider's dashboard.

## Technical Notes

### Stack alignment note — NO React
The raw spec included React components (`RestaurantMap.jsx`, `RestaurantMarker.jsx`). The Smart Menu stack uses Hotwire (Turbo + Stimulus) with Bootstrap 5 and esbuild — no React. The map component must be a Stimulus controller.

### Map provider recommendation
Mapbox GL JS is preferable to Google Maps for v1:
- Generous free tier (50,000 map loads/month)
- Vector tiles load faster on mobile
- No per-request billing on tile loads
- Easily customisable without paying for premium Google styles

Load Mapbox GL JS via CDN in the Stimulus controller's `connect()` method (lazy load). If Google Maps is already contractually in use for another feature, reuse that key.

### New migration: Restaurant location fields
Rather than a separate `RestaurantLocation` model, add lat/lng directly to `Restaurant` for simplicity:
```ruby
add_column :restaurants, :latitude,       :decimal, precision: 10, scale: 6
add_column :restaurants, :longitude,      :decimal, precision: 10, scale: 6
add_column :restaurants, :map_visible,    :boolean, null: false, default: true
add_column :restaurants, :map_featured,   :boolean, null: false, default: false
add_column :restaurants, :cuisine_tags,   :string,  array: true, default: []
add_column :restaurants, :price_range,    :integer  # 1–4 ($ to $$$$)
add_index  :restaurants, [:latitude, :longitude]
add_index  :restaurants, :map_visible
```

If the data model grows (multi-location restaurant groups, each with their own address), extract to a `RestaurantLocation` model in v2.

### Geocoding
`app/jobs/geocode_restaurant_job.rb` — triggered when a restaurant opts in to map visibility or updates their address. Uses a geocoding service (Geocoder gem or direct Mapbox Geocoding API call) to set `latitude` and `longitude` on the `Restaurant`. Results are cached — do not re-geocode on every settings save.

### Service: map data query
`app/services/restaurants/map_discovery_service.rb`:
- Accepts bounding box (sw_lat, sw_lng, ne_lat, ne_lng)
- Returns opted-in restaurants within the bounding box
- Applies a max of 100 results per request to prevent large data dumps
- Uses read replica for this query (analytics/discovery pattern)

### Analytics
Lightweight `MapAnalytic` model (no index needed beyond `restaurant_id` and `created_at`):
```ruby
create_table :map_analytics do |t|
  t.references :restaurant, null: false, foreign_key: true
  t.string     :event_type, null: false  # 'marker_click', 'menu_click'
  t.string     :session_id
  t.datetime   :created_at, null: false
  t.index [:restaurant_id, :created_at]
end
```

Write via `RecordMapAnalyticJob` — fire and forget. No PII stored.

### Pundit policy
`MapAnalyticPolicy` — not needed (no user auth required for public discovery page). The restaurant settings toggle uses the existing `RestaurantPolicy`.

### Flipper flag
- `nearby_menus_map` — gates the `/discover` page and the map visibility toggle in restaurant settings

## Acceptance Criteria
1. The `/discover` page loads and renders the static shell (header, map container, search input) in under 1 second on a fast connection.
2. Map markers appear for all `map_visible: true` restaurants with geocoded coordinates within the current viewport.
3. Clicking a marker opens a popup with the restaurant name, a "View Menu" link, and at least one additional data point (cuisine tag or price range).
4. The "View Menu" link navigates to the restaurant's SmartMenu URL.
5. A restaurant that has set `map_visible: false` does not appear on the map even if the URL is queried directly.
6. A restaurant admin toggling map visibility off in restaurant settings causes their marker to disappear on the next map data refresh (within 5 minutes, via cache expiry or immediate cache invalidation).
7. A `MapAnalytic` record with `event_type: 'menu_click'` is created when a visitor clicks "View Menu" from a popup.
8. The restaurant's analytics dashboard shows a non-zero "Discover Map views" count after a menu click event has been recorded.
9. The `nearby_menus_map` Flipper flag, when disabled, returns a 404 for the `/discover` route.
10. Map marker clustering is active at zoom levels below 12 — overlapping markers are grouped into a count badge.

## Out of Scope
- User accounts on the discovery page (anonymous browsing only in v1)
- Filtering by cuisine, price range, or dietary restrictions (v2)
- Restaurant ratings or reviews on the map popup
- Real-time table availability or current wait time on the map

## Open Questions
1. Is PostGIS already enabled in the production database? If not, a bounding-box approximation (WHERE latitude BETWEEN x AND y AND longitude BETWEEN a AND b) is the v1 fallback. Confirm with infra before writing the service.
2. Which map provider is preferred — Mapbox or Google Maps? Does the team have an existing Google Maps API key for other features?
3. Should the `/discover` page be crawled by search engines? If yes, server-side rendered restaurant cards (not just JS markers) are needed for SEO. Confirm with marketing.
4. What is the expected number of mellow.menu restaurants at launch? This determines whether the 100-result-per-bounding-box limit is appropriate or too aggressive.

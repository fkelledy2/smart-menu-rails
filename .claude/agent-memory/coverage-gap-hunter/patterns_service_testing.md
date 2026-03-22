---
name: service_testing_patterns
description: Service object test patterns, quick-win categories, and specific gotchas for Smart Menu
type: feedback
---

## Quick-win service categories (fastest coverage gains)

### 1. Pure logic services (no DB, no external calls)
Test these first — 100% coverage achievable with just Minitest.
- `VoiceCommandIntentService` — regex-based intent parsing
- `MenuVersionDiffService` — pure hash diffing
- `CountryCurrencyInference` — country → currency lookup
- `EstablishmentTypeInference` — Google Places type → label mapping

### 2. Guard/early-return paths
Test nil/blank input first — these cover the guard lines cheaply.
```ruby
test 'returns false for nil input' do
  assert_equal false, MyService.method(nil)
end
```

### 3. Class-method services
Services with `self.method_name` class methods are simpler to test (no `new` + setup).
Pattern: `MyService.call(args)` or `MyService.method_name(args)`

## ActionCable broadcast suppression

When testing services that create `OrdrStationTicket` records (which trigger `after_commit` callbacks
that call `ActionCable.server.broadcast`), suppress the broadcast:

```ruby
ActionCable.server.stub(:broadcast, nil) do
  # ... test code that creates/updates tickets
end
```

Without this stub, tests will fail with connection errors in the test environment.

## FK constraint gotcha — ordr_station_ticket_id

`ordritems.ordr_station_ticket_id` has a FK constraint.
Cannot use `update_all(ordr_station_ticket_id: 99_999_999)` to simulate a linked ticket.
Must create a real `OrdrStationTicket` record first.

## Tempfile pattern for CSV tests

```ruby
def create_csv_file(content)
  file = Tempfile.new(['name', '.csv'])
  file.write(content)
  file.rewind
  file
ensure
  # caller must: csv.close; csv.unlink
end
```

## RestaurantArchivalService on_primary

`RestaurantArchivalService#archive!` and `#restore!` wrap in `Restaurant.on_primary {}`.
In tests, this executes on the primary database (test DB) — no special setup needed.
The guard `return if @restaurant.archived == true` (for archive!) and `return unless @restaurant.archived == true` (for restore!) make idempotency tests very simple.

## Empty result sets in insights services

`RestaurantInsightsService#top_performers` queries `Ordritem.joins(:ordr)...` with date filters.
Fixture ordrs have `created_at: 1.day.ago` — they will appear in default date ranges.
But ordering by `orders_with_item_count DESC` means the result may be empty if no ordritems
are in active status joined to active menuitems.
Use `pass` at end of iteration-based tests to avoid "missing assertions" warning when result is empty.

## Minitest stub pattern

```ruby
SomeClass.stub(:method_name, return_value) do
  # code under test
end
```
Works for class methods. For instance methods: `object.stub(:method, value) do ... end`

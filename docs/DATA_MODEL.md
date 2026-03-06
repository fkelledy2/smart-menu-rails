# Data Model

> **Auto-generated** by `bin/generate_docs` on 2026-03-06 12:23 UTC

---

## 1. Database Overview

| Property | Value |
|---|---|
| **Engine** | PostgreSQL 14+ |
| **Extensions** | `plpgsql`, `vector` |
| **Total Tables** | 105 |
| **Schema Version** | `2026_03_05_080000` |

---

## 2. Table Summary

| Table | Columns | Indexes | PK Type |
|---|---|---|---|
| `active_storage_attachments` | 5 | 2 | bigint |
| `active_storage_blobs` | 8 | 1 | bigint |
| `active_storage_variant_records` | 2 | 1 | bigint |
| `alcohol_order_events` | 13 | 7 | bigint |
| `alcohol_policies` | 6 | 1 | bigint |
| `allergyns` | 9 | 2 | bigint |
| `announcements` | 6 | 0 | bigint |
| `beverage_pipeline_runs` | 12 | 3 | bigint |
| `contacts` | 4 | 2 | bigint |
| `crawl_source_rules` | 6 | 3 | bigint |
| `discovered_restaurants` | 25 | 4 | bigint |
| `employees` | 12 | 6 | bigint |
| `explore_pages` | 13 | 3 | bigint |
| `features` | 5 | 0 | bigint |
| `features_plans` | 6 | 3 | bigint |
| `flavor_profiles` | 7 | 3 | bigint |
| `flipper_features` | 3 | 1 | bigint |
| `flipper_gates` | 5 | 1 | bigint |
| `friendly_id_slugs` | 5 | 3 | bigint |
| `genimages` | 10 | 6 | bigint |
| `hero_images` | 7 | 2 | bigint |
| `impersonation_audits` | 11 | 5 | bigint |
| `ingredients` | 5 | 0 | bigint |
| `inventories` | 9 | 5 | bigint |
| `ledger_events` | 12 | 3 | bigint |
| `local_guides` | 15 | 4 | bigint |
| `memory_metrics` | 8 | 2 | bigint |
| `menu_edit_sessions` | 8 | 5 | bigint |
| `menu_imports` | 7 | 4 | bigint |
| `menu_item_product_links` | 7 | 3 | bigint |
| `menu_items` | 8 | 1 | bigint |
| `menu_sections` | 6 | 1 | bigint |
| `menu_source_change_reviews` | 14 | 3 | bigint |
| `menu_sources` | 12 | 5 | bigint |
| `menu_versions` | 9 | 5 | bigint |
| `menuavailabilities` | 11 | 3 | bigint |
| `menuitem_allergyn_mappings` | 4 | 3 | bigint |
| `menuitem_ingredient_mappings` | 4 | 3 | bigint |
| `menuitem_size_mappings` | 5 | 3 | bigint |
| `menuitem_tag_mappings` | 4 | 3 | bigint |
| `menuitemlocales` | 7 | 3 | bigint |
| `menuitems` | 30 | 16 | bigint |
| `menulocales` | 7 | 2 | bigint |
| `menuparticipants` | 5 | 4 | bigint |
| `menus` | 23 | 10 | bigint |
| `menusectionlocales` | 7 | 3 | bigint |
| `menusections` | 27 | 5 | bigint |
| `metrics` | 7 | 1 | bigint |
| `noticed_events` | 7 | 1 | bigint |
| `noticed_notifications` | 8 | 2 | bigint |
| `ocr_menu_imports` | 14 | 6 | bigint |
| `ocr_menu_items` | 18 | 10 | bigint |
| `ocr_menu_sections` | 11 | 6 | bigint |
| `onboarding_sessions` | 7 | 5 | bigint |
| `order_events` | 11 | 4 | bigint |
| `ordr_split_payments` | 13 | 6 | bigint |
| `ordr_station_tickets` | 8 | 4 | bigint |
| `ordractions` | 6 | 4 | bigint |
| `ordritemnotes` | 4 | 1 | bigint |
| `ordritems` | 9 | 9 | bigint |
| `ordrparticipant_allergyn_filters` | 4 | 3 | bigint |
| `ordrparticipants` | 9 | 6 | bigint |
| `ordrs` | 23 | 17 | serial |
| `pairing_recommendations` | 10 | 3 | bigint |
| `pay_charges` | 13 | 2 | bigint |
| `pay_customers` | 11 | 2 | bigint |
| `pay_merchants` | 9 | 2 | bigint |
| `pay_payment_methods` | 9 | 1 | bigint |
| `pay_subscriptions` | 22 | 4 | bigint |
| `pay_webhooks` | 5 | 0 | bigint |
| `payment_attempts` | 16 | 6 | bigint |
| `payment_profiles` | 9 | 1 | bigint |
| `payment_refunds` | 11 | 5 | bigint |
| `performance_metrics` | 11 | 5 | bigint |
| `plans` | 21 | 2 | bigint |
| `product_enrichments` | 8 | 3 | bigint |
| `products` | 5 | 1 | bigint |
| `provider_accounts` | 18 | 3 | bigint |
| `push_subscriptions` | 7 | 3 | bigint |
| `resource_locks` | 9 | 4 | bigint |
| `restaurant_claim_requests` | 12 | 4 | bigint |
| `restaurant_menus` | 11 | 4 | bigint |
| `restaurant_onboardings` | 6 | 1 | bigint |
| `restaurant_removal_requests` | 10 | 3 | bigint |
| `restaurant_subscriptions` | 9 | 3 | bigint |
| `restaurantavailabilities` | 11 | 1 | bigint |
| `restaurantlocales` | 7 | 4 | bigint |
| `restaurants` | 65 | 10 | bigint |
| `services` | 10 | 1 | bigint |
| `similar_product_recommendations` | 6 | 3 | bigint |
| `sizes` | 10 | 3 | bigint |
| `slow_queries` | 7 | 2 | bigint |
| `smartmenus` | 6 | 8 | bigint |
| `staff_invitations` | 10 | 5 | bigint |
| `tablesettings` | 10 | 3 | bigint |
| `tags` | 6 | 0 | bigint |
| `taxes` | 9 | 2 | bigint |
| `testimonials` | 7 | 2 | bigint |
| `tips` | 7 | 2 | bigint |
| `tracks` | 12 | 1 | bigint |
| `user_sessions` | 9 | 5 | bigint |
| `userplans` | 4 | 2 | bigint |
| `users` | 22 | 7 | bigint |
| `voice_commands` | 11 | 3 | bigint |
| `whiskey_flights` | 12 | 3 | bigint |

---

## 3. Foreign Keys

| From | To |
|---|---|
| `active_storage_attachments` | `active_storage_blobs` |
| `active_storage_variant_records` | `active_storage_blobs` |
| `alcohol_order_events` | `menuitems` |
| `alcohol_order_events` | `ordritems` |
| `alcohol_order_events` | `ordrs` |
| `alcohol_order_events` | `restaurants` |
| `alcohol_policies` | `restaurants` |
| `allergyns` | `restaurants` |
| `beverage_pipeline_runs` | `menus` |
| `beverage_pipeline_runs` | `restaurants` |
| `crawl_source_rules` | `users` |
| `discovered_restaurants` | `restaurants` |
| `employees` | `restaurants` |
| `employees` | `users` |
| `features_plans` | `features` |
| `features_plans` | `plans` |
| `genimages` | `menuitems` |
| `genimages` | `menus` |
| `genimages` | `menusections` |
| `genimages` | `restaurants` |
| `impersonation_audits` | `users` |
| `impersonation_audits` | `users` |
| `inventories` | `menuitems` |
| `menu_edit_sessions` | `menus` |
| `menu_edit_sessions` | `users` |
| `menu_imports` | `restaurants` |
| `menu_imports` | `users` |
| `menu_item_product_links` | `menuitems` |
| `menu_item_product_links` | `products` |
| `menu_items` | `menu_sections` |
| `menu_sections` | `menus` |
| `menu_source_change_reviews` | `menu_sources` |
| `menu_sources` | `discovered_restaurants` |
| `menu_sources` | `restaurants` |
| `menu_versions` | `menus` |
| `menu_versions` | `users` |
| `menuavailabilities` | `menus` |
| `menuitem_allergyn_mappings` | `allergyns` |
| `menuitem_allergyn_mappings` | `menuitems` |
| `menuitem_ingredient_mappings` | `ingredients` |
| `menuitem_ingredient_mappings` | `menuitems` |
| `menuitem_size_mappings` | `menuitems` |
| `menuitem_size_mappings` | `sizes` |
| `menuitem_tag_mappings` | `menuitems` |
| `menuitem_tag_mappings` | `tags` |
| `menuitemlocales` | `menuitems` |
| `menuitems` | `menusections` |
| `menulocales` | `menus` |
| `menuparticipants` | `smartmenus` |
| `menus` | `menu_imports` |
| `menus` | `restaurants` |
| `menus` | `restaurants` |
| `menus` | `users` |
| `menusectionlocales` | `menusections` |
| `menusections` | `menus` |
| `ocr_menu_imports` | `menus` |
| `ocr_menu_imports` | `restaurants` |
| `ocr_menu_items` | `menu_items` |
| `ocr_menu_items` | `menuitems` |
| `ocr_menu_items` | `ocr_menu_sections` |
| `ocr_menu_sections` | `menu_sections` |
| `ocr_menu_sections` | `menusections` |
| `ocr_menu_sections` | `ocr_menu_imports` |
| `onboarding_sessions` | `menus` |
| `onboarding_sessions` | `restaurants` |
| `onboarding_sessions` | `users` |
| `order_events` | `ordrs` |
| `ordr_split_payments` | `ordrparticipants` |
| `ordr_split_payments` | `ordrs` |
| `ordr_station_tickets` | `ordrs` |
| `ordr_station_tickets` | `restaurants` |
| `ordractions` | `ordritems` |
| `ordractions` | `ordrparticipants` |
| `ordritemnotes` | `ordritems` |
| `ordritems` | `menuitems` |
| `ordritems` | `ordr_station_tickets` |
| `ordrparticipant_allergyn_filters` | `allergyns` |
| `ordrparticipant_allergyn_filters` | `ordrparticipants` |
| `ordrparticipants` | `employees` |
| `ordrparticipants` | `ordritems` |
| `ordrs` | `employees` |
| `ordrs` | `menus` |
| `ordrs` | `restaurants` |
| `ordrs` | `tablesettings` |
| `pairing_recommendations` | `menuitems` |
| `pairing_recommendations` | `menuitems` |
| `pay_charges` | `pay_customers` |
| `pay_charges` | `pay_subscriptions` |
| `pay_payment_methods` | `pay_customers` |
| `pay_subscriptions` | `pay_customers` |
| `payment_attempts` | `ordrs` |
| `payment_attempts` | `restaurants` |
| `payment_profiles` | `restaurants` |
| `payment_refunds` | `ordrs` |
| `payment_refunds` | `payment_attempts` |
| `payment_refunds` | `restaurants` |
| `performance_metrics` | `users` |
| `product_enrichments` | `products` |
| `provider_accounts` | `restaurants` |
| `push_subscriptions` | `users` |
| `resource_locks` | `users` |
| `restaurant_claim_requests` | `restaurants` |
| `restaurant_claim_requests` | `users` |
| `restaurant_claim_requests` | `users` |
| `restaurant_menus` | `menus` |
| `restaurant_menus` | `restaurants` |
| `restaurant_menus` | `users` |
| `restaurant_onboardings` | `restaurants` |
| `restaurant_removal_requests` | `restaurants` |
| `restaurant_removal_requests` | `users` |
| `restaurant_subscriptions` | `restaurants` |
| `restaurantavailabilities` | `restaurants` |
| `restaurantlocales` | `restaurants` |
| `restaurants` | `users` |
| `restaurants` | `users` |
| `services` | `users` |
| `similar_product_recommendations` | `products` |
| `similar_product_recommendations` | `products` |
| `sizes` | `restaurants` |
| `smartmenus` | `menus` |
| `smartmenus` | `restaurants` |
| `smartmenus` | `tablesettings` |
| `staff_invitations` | `restaurants` |
| `staff_invitations` | `users` |
| `tablesettings` | `restaurants` |
| `taxes` | `restaurants` |
| `testimonials` | `restaurants` |
| `testimonials` | `users` |
| `tips` | `restaurants` |
| `tracks` | `restaurants` |
| `user_sessions` | `users` |
| `userplans` | `plans` |
| `userplans` | `users` |
| `voice_commands` | `smartmenus` |
| `whiskey_flights` | `menus` |

---

## 4. Core Table Details (23 tables)

> Only core domain tables are detailed below. For full column listings of
> all 105 tables, inspect `db/schema.rb` directly.

### `allergyns`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `symbol` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived` | boolean | , default: false |
| `status` | integer | , default: 0 |
| `sequence` | integer | — |
| `restaurant_id` | bigint | — |

**Indexes:**
- `t.index ["restaurant_id", "status"], name: "index_allergyns_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id"], name: "index_allergyns_on_restaurant_id"`


---

### `employees`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `eid` | string | — |
| `image` | string | — |
| `status` | integer | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `role` | integer | — |
| `email` | string | — |
| `user_id` | bigint | , null: false |
| `archived` | boolean | , default: false |
| `sequence` | integer | — |

**Indexes:**
- `t.index ["email"], name: "index_employees_on_email"`
- `t.index ["restaurant_id", "created_at"], name: "index_employees_on_restaurant_created_at"`
- `t.index ["restaurant_id", "role", "status"], name: "index_employees_on_restaurant_role_status", where: "(archived = false)"`
- `t.index ["restaurant_id", "status"], name: "index_employees_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id"], name: "index_employees_on_restaurant_id"`
- `t.index ["user_id"], name: "index_employees_on_user_id"`


---

### `inventories`

| Column | Type | Options |
|---|---|---|
| `startinginventory` | integer | — |
| `currentinventory` | integer | — |
| `resethour` | integer | — |
| `menuitem_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived` | boolean | , default: false |
| `status` | integer | , default: 0 |
| `sequence` | integer | — |

**Indexes:**
- `t.index ["archived"], name: "index_inventories_on_archived"`
- `t.index ["menuitem_id", "status"], name: "index_inventories_on_menuitem_status_active", where: "(archived = false)"`
- `t.index ["menuitem_id", "updated_at"], name: "index_inventories_on_menuitem_updated_at"`
- `t.index ["menuitem_id"], name: "index_inventories_on_menuitem_id"`
- `t.index ["status"], name: "index_inventories_on_status"`


---

### `ledger_events`

| Column | Type | Options |
|---|---|---|
| `entity_type` | integer | , default: 0, null: false |
| `entity_id` | bigint | — |
| `event_type` | integer | , default: 0, null: false |
| `amount_cents` | integer | — |
| `currency` | string | — |
| `provider` | integer | , default: 0, null: false |
| `provider_event_id` | string | , null: false |
| `provider_event_type` | string | — |
| `raw_event_payload` | jsonb | , default: {}, null: false |
| `occurred_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["entity_type", "entity_id"], name: "index_ledger_events_on_entity_type_and_entity_id"`
- `t.index ["occurred_at"], name: "index_ledger_events_on_occurred_at"`
- `t.index ["provider", "provider_event_id"], name: "index_ledger_events_on_provider_and_provider_event_id", unique: true`


---

### `menuavailabilities`

| Column | Type | Options |
|---|---|---|
| `dayofweek` | integer | — |
| `starthour` | integer | — |
| `startmin` | integer | — |
| `endhour` | integer | — |
| `endmin` | integer | — |
| `menu_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `status` | integer | — |
| `sequence` | integer | — |
| `archived` | boolean | , default: false |

**Indexes:**
- `t.index ["menu_id", "dayofweek", "starthour"], name: "index_menuavailabilities_on_menu_day_time", where: "(archived = false)"`
- `t.index ["menu_id", "dayofweek"], name: "index_menuavailabilities_on_menu_and_dayofweek", unique: true`
- `t.index ["menu_id"], name: "index_menuavailabilities_on_menu_id"`


---

### `menuitem_allergyn_mappings`

| Column | Type | Options |
|---|---|---|
| `menuitem_id` | bigint | , null: false |
| `allergyn_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["allergyn_id", "menuitem_id"], name: "index_menuitem_allergyn_on_allergyn_menuitem"`
- `t.index ["allergyn_id"], name: "index_menuitem_allergyn_mappings_on_allergyn_id"`
- `t.index ["menuitem_id"], name: "index_menuitem_allergyn_mappings_on_menuitem_id"`


---

### `menuitems`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `status` | integer | — |
| `sequence` | integer | — |
| `calories` | integer | — |
| `price` | float | — |
| `menusection_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `preptime` | integer | , default: 0 |
| `archived` | boolean | , default: false |
| `image_data` | text | — |
| `itemtype` | integer | , default: 0 |
| `sizesupport` | boolean | , default: false |
| `unitcost` | float | , default: 0.0 |
| `tasting_optional` | boolean | , default: false, null: false |
| `tasting_supplement_cents` | integer | — |
| `tasting_supplement_currency` | string | — |
| `course_order` | integer | — |
| `hidden` | boolean | , default: false, null: false |
| `tasting_carrier` | boolean | , default: false, null: false |
| `abv` | decimal | , precision: 5, scale: 2 |
| `alcohol_classification` | string | — |
| `alcohol_notes` | text | — |
| `sommelier_classification_confidence` | decimal | , precision: 5, scale: 4 |
| `sommelier_parsed_fields` | jsonb | , default: {}, null: false |
| `sommelier_parse_confidence` | decimal | , precision: 5, scale: 4 |
| `sommelier_needs_review` | boolean | , default: false, null: false |
| `image_prompt` | text | — |
| `ordritems_count` | integer | , default: 0 |

**Indexes:**
- `t.index "lower((name)::text) varchar_pattern_ops", name: "index_menuitems_on_lower_name"`
- `t.index ["alcohol_classification"], name: "index_menuitems_on_alcohol_classification"`
- `t.index ["archived"], name: "index_menuitems_on_archived"`
- `t.index ["course_order"], name: "index_menuitems_on_course_order"`
- `t.index ["created_at"], name: "index_menuitems_on_created_at"`
- `t.index ["hidden"], name: "index_menuitems_on_hidden"`
- `t.index ["menusection_id", "sequence"], name: "index_menuitems_on_menusection_sequence"`
- `t.index ["menusection_id", "status", "sequence"], name: "index_menuitems_on_section_status_sequence", where: "(archived = false)"`
- `t.index ["menusection_id", "status"], name: "index_menuitems_on_menusection_status"`
- `t.index ["menusection_id", "status"], name: "index_menuitems_on_section_status_active", where: "(archived = false)"`
- `t.index ["menusection_id", "tasting_carrier"], name: "index_menuitems_on_section_and_carrier"`
- `t.index ["menusection_id"], name: "index_menuitems_on_menusection_id"`
- `t.index ["sequence"], name: "index_menuitems_on_sequence"`
- `t.index ["sommelier_needs_review"], name: "index_menuitems_on_sommelier_needs_review"`
- `t.index ["status"], name: "index_menuitems_on_status"`
- `t.index ["updated_at"], name: "index_menuitems_on_updated_at"`


---

### `menus`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `status` | integer | — |
| `sequence` | integer | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `displayImages` | boolean | , default: false |
| `allowOrdering` | boolean | , default: false |
| `inventoryTracking` | boolean | , default: false |
| `archived` | boolean | , default: false |
| `image_data` | text | — |
| `imagecontext` | string | — |
| `displayImagesInPopup` | boolean | , default: false |
| `covercharge` | float | , default: 0.0 |
| `menu_import_id` | bigint | — |
| `voiceOrderingEnabled` | boolean | , default: false |
| `owner_restaurant_id` | bigint | — |
| `menuitems_count` | integer | , default: 0 |
| `menusections_count` | integer | , default: 0 |
| `archived_at` | datetime | — |
| `archived_reason` | string | — |
| `archived_by_id` | bigint | — |

**Indexes:**
- `t.index ["archived"], name: "index_menus_on_archived"`
- `t.index ["archived_by_id"], name: "index_menus_on_archived_by_id"`
- `t.index ["menu_import_id"], name: "index_menus_on_menu_import_id"`
- `t.index ["menuitems_count"], name: "index_menus_on_menuitems_count"`
- `t.index ["owner_restaurant_id"], name: "index_menus_on_owner_restaurant_id"`
- `t.index ["restaurant_id", "created_at"], name: "index_menus_on_restaurant_created_at"`
- `t.index ["restaurant_id", "status"], name: "index_menus_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id", "updated_at"], name: "index_menus_on_restaurant_updated_at"`
- `t.index ["restaurant_id"], name: "index_menus_on_restaurant_id"`
- `t.index ["status"], name: "index_menus_on_status"`


---

### `menusections`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `image` | string | — |
| `status` | integer | — |
| `sequence` | integer | — |
| `menu_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived` | boolean | , default: false |
| `image_data` | text | — |
| `fromhour` | integer | , default: 0 |
| `frommin` | integer | , default: 0 |
| `tohour` | integer | , default: 23 |
| `tomin` | integer | , default: 59 |
| `restricted` | boolean | , default: false |
| `tasting_menu` | boolean | , default: false, null: false |
| `tasting_price_cents` | integer | — |
| `tasting_currency` | string | — |
| `price_per` | string | , default: "person" |
| `min_party_size` | integer | — |
| `max_party_size` | integer | — |
| `includes_description` | text | — |
| `allow_substitutions` | boolean | , default: false, null: false |
| `allow_pairing` | boolean | , default: false, null: false |
| `pairing_price_cents` | integer | — |
| `pairing_currency` | string | — |
| `menuitems_count` | integer | , default: 0 |

**Indexes:**
- `t.index ["menu_id", "sequence"], name: "index_menusections_on_menu_and_sequence"`
- `t.index ["menu_id", "status", "sequence"], name: "index_menusections_on_menu_status_sequence", where: "(archived = false)"`
- `t.index ["menu_id"], name: "index_menusections_on_menu_id"`
- `t.index ["menuitems_count"], name: "index_menusections_on_menuitems_count"`
- `t.index ["tasting_menu"], name: "index_menusections_on_tasting_menu"`


---

### `ordractions`

| Column | Type | Options |
|---|---|---|
| `action` | integer | — |
| `ordrparticipant_id` | bigint | , null: false |
| `ordr_id` | bigint | , null: false |
| `ordritem_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["ordr_id"], name: "index_ordractions_on_ordr_id"`
- `t.index ["ordritem_id"], name: "index_ordractions_on_ordritem_id"`
- `t.index ["ordrparticipant_id", "ordr_id", "action"], name: "index_ordractions_on_participant_ordr_action"`
- `t.index ["ordrparticipant_id"], name: "index_ordractions_on_ordrparticipant_id"`


---

### `ordritemnotes`

| Column | Type | Options |
|---|---|---|
| `note` | string | — |
| `ordritem_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["ordritem_id"], name: "index_ordritemnotes_on_ordritem_id"`


---

### `ordritems`

| Column | Type | Options |
|---|---|---|
| `ordr_id` | bigint | , null: false |
| `menuitem_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `ordritemprice` | float | , default: 0.0 |
| `status` | integer | , default: 0 |
| `ordr_station_ticket_id` | bigint | — |
| `line_key` | string | , null: false |
| `size_name` | string | — |

**Indexes:**
- `t.index ["created_at"], name: "index_ordritems_on_created_at"`
- `t.index ["menuitem_id", "status"], name: "index_ordritems_on_menuitem_status"`
- `t.index ["menuitem_id"], name: "index_ordritems_on_menuitem_id"`
- `t.index ["ordr_id", "created_at"], name: "index_ordritems_on_ordr_created_at"`
- `t.index ["ordr_id", "line_key"], name: "index_ordritems_on_ordr_id_and_line_key", unique: true`
- `t.index ["ordr_id", "status"], name: "index_ordritems_on_ordr_status"`
- `t.index ["ordr_id"], name: "index_ordritems_on_ordr_id"`
- `t.index ["ordr_station_ticket_id"], name: "index_ordritems_on_ordr_station_ticket_id"`
- `t.index ["status"], name: "index_ordritems_on_status"`


---

### `ordrparticipants`

| Column | Type | Options |
|---|---|---|
| `sessionid` | string | — |
| `role` | integer | — |
| `ordr_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `name` | string | — |
| `ordritem_id` | bigint | — |
| `employee_id` | bigint | — |
| `preferredlocale` | string | — |

**Indexes:**
- `t.index ["employee_id"], name: "index_ordrparticipants_on_employee_id"`
- `t.index ["ordr_id", "role", "employee_id"], name: "index_ordrparticipants_on_ordr_role_employee"`
- `t.index ["ordr_id", "role", "sessionid"], name: "index_ordrparticipants_on_ordr_role_session"`
- `t.index ["ordr_id"], name: "index_ordrparticipants_on_ordr_id"`
- `t.index ["ordritem_id"], name: "index_ordrparticipants_on_ordritem_id"`
- `t.index ["sessionid", "preferredlocale"], name: "index_ordrparticipants_on_session_locale"`


---

### `ordrs`

| Column | Type | Options |
|---|---|---|
| `orderedAt` | datetime | , precision: nil |
| `deliveredAt` | datetime | , precision: nil |
| `paidAt` | datetime | , precision: nil |
| `nett` | float | — |
| `tip` | float | — |
| `service` | float | — |
| `tax` | float | — |
| `gross` | float | — |
| `employee_id` | integer | — |
| `tablesetting_id` | bigint | , null: false |
| `menu_id` | bigint | , null: false |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , precision: nil, null: false |
| `updated_at` | datetime | , precision: nil, null: false |
| `status` | integer | — |
| `billRequestedAt` | datetime | — |
| `ordercapacity` | integer | , default: 0 |
| `covercharge` | float | , default: 0.0 |
| `paymentlink` | string | — |
| `paymentstatus` | integer | , default: 0 |
| `last_projected_order_event_sequence` | bigint | , default: 0, null: false |
| `ordritems_count` | integer | , default: 0 |
| `ordrparticipants_count` | integer | , default: 0 |

**Indexes:**
- `t.index ["created_at"], name: "index_ordrs_on_created_at"`
- `t.index ["employee_id", "created_at"], name: "index_ordrs_on_employee_created_at"`
- `t.index ["employee_id"], name: "index_ordrs_on_employee_id"`
- `t.index ["last_projected_order_event_sequence"], name: "index_ordrs_on_last_projected_order_event_sequence"`
- `t.index ["menu_id", "tablesetting_id", "status"], name: "index_ordrs_on_menu_table_status"`
- `t.index ["menu_id"], name: "index_ordrs_on_menu_id"`
- `t.index ["ordritems_count"], name: "index_ordrs_on_ordritems_count"`
- `t.index ["restaurant_id", "created_at", "gross"], name: "index_ordrs_on_restaurant_created_gross"`
- `t.index ["restaurant_id", "created_at", "status"], name: "index_ordrs_on_restaurant_created_status"`
- `t.index ["restaurant_id", "status", "created_at"], name: "index_ordrs_on_restaurant_status_created"`
- `t.index ["restaurant_id", "status"], name: "index_ordrs_on_restaurant_status"`
- `t.index ["restaurant_id"], name: "index_ordrs_on_restaurant_id"`
- `t.index ["status"], name: "index_ordrs_on_status"`
- `t.index ["tablesetting_id", "status", "created_at"], name: "index_ordrs_on_table_status_created"`
- `t.index ["tablesetting_id", "status"], name: "index_ordrs_on_tablesetting_and_status"`
- `t.index ["tablesetting_id"], name: "index_ordrs_on_tablesetting_id"`
- `t.index ["updated_at"], name: "index_ordrs_on_updated_at"`


---

### `plans`

| Column | Type | Options |
|---|---|---|
| `key` | string | — |
| `descriptionKey` | string | — |
| `attribute1` | string | — |
| `attribute2` | string | — |
| `attribute3` | string | — |
| `attribute4` | string | — |
| `attribute5` | string | — |
| `attribut6` | string | — |
| `status` | integer | — |
| `favourite` | boolean | — |
| `pricePerMonth` | decimal | — |
| `pricePerYear` | decimal | — |
| `action` | integer | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `itemspermenu` | integer | , default: 0 |
| `languages` | integer | , default: 0 |
| `locations` | integer | , default: 0 |
| `menusperlocation` | integer | , default: 0 |
| `stripe_price_id_month` | string | — |
| `stripe_price_id_year` | string | — |

**Indexes:**
- `t.index ["stripe_price_id_month"], name: "index_plans_on_stripe_price_id_month"`
- `t.index ["stripe_price_id_year"], name: "index_plans_on_stripe_price_id_year"`


---

### `restaurants`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `address1` | string | — |
| `address2` | string | — |
| `state` | string | — |
| `city` | string | — |
| `postcode` | string | — |
| `country` | string | — |
| `status` | integer | — |
| `capacity` | integer | — |
| `user_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `genid` | string | — |
| `displayImages` | boolean | , default: false |
| `allowOrdering` | boolean | , default: false |
| `inventoryTracking` | boolean | , default: false |
| `currency` | string | — |
| `archived` | boolean | , default: false |
| `latitude` | float | — |
| `longitude` | float | — |
| `sequence` | integer | — |
| `image_data` | text | — |
| `imagecontext` | string | — |
| `wifissid` | string | — |
| `wifiEncryptionType` | integer | , default: 0 |
| `wifiPassword` | string | — |
| `wifiHidden` | boolean | , default: false |
| `spotifyuserid` | string | — |
| `spotifyaccesstoken` | string | — |
| `spotifyrefreshtoken` | string | — |
| `displayImagesInPopup` | boolean | , default: false |
| `image_style_profile` | text | — |
| `allow_alcohol` | boolean | , default: false, null: false |
| `timezone` | string | , default: "UTC" |
| `menus_count` | integer | , default: 0 |
| `employees_count` | integer | , default: 0 |
| `ordrs_count` | integer | , default: 0 |
| `tablesettings_count` | integer | , default: 0 |
| `ocr_menu_imports_count` | integer | , default: 0 |
| `archived_at` | datetime | — |
| `archived_reason` | string | — |
| `archived_by_id` | bigint | — |
| `google_place_id` | string | — |
| `claim_status` | integer | , default: 0, null: false |
| `preview_enabled` | boolean | , default: false, null: false |
| `preview_published_at` | datetime | — |
| `preview_indexable` | boolean | , default: false, null: false |
| `establishment_types` | string | , default: [], null: false, array: true |
| `provisioned_by` | integer | , default: 0 |
| `source_url` | string | — |
| `ordering_enabled` | boolean | , default: false, null: false |
| `payments_enabled` | boolean | , default: false, null: false |
| `whiskey_ambassador_enabled` | boolean | , default: false, null: false |
| `max_whiskey_flights` | integer | , default: 5, null: false |
| `payment_provider` | string | , default: "stripe" |
| `payment_provider_status` | integer | , default: 0, null: false |
| `square_checkout_mode` | integer | , default: 0, null: false |
| `square_location_id` | string | — |
| `square_merchant_id` | string | — |
| `square_application_id` | string | — |
| `square_oauth_revoked_at` | datetime | — |
| `platform_fee_type` | integer | , default: 0, null: false |
| `platform_fee_percent` | decimal | , precision: 5, scale: 2 |
| `platform_fee_fixed_cents` | integer | — |

**Indexes:**
- `t.index ["archived_by_id"], name: "index_restaurants_on_archived_by_id"`
- `t.index ["city", "country", "preview_enabled"], name: "idx_restaurants_geo_preview"`
- `t.index ["claim_status"], name: "index_restaurants_on_claim_status"`
- `t.index ["employees_count"], name: "index_restaurants_on_employees_count"`
- `t.index ["google_place_id"], name: "index_restaurants_on_google_place_id", unique: true`
- `t.index ["menus_count"], name: "index_restaurants_on_menus_count"`
- `t.index ["preview_enabled", "claim_status"], name: "idx_restaurants_preview_claim"`
- `t.index ["preview_published_at"], name: "index_restaurants_on_preview_published_at"`
- `t.index ["user_id", "status"], name: "index_restaurants_on_user_status_active", where: "(archived = false)"`
- `t.index ["user_id"], name: "index_restaurants_on_user_id"`


---

### `sizes`

| Column | Type | Options |
|---|---|---|
| `size` | integer | — |
| `name` | string | — |
| `description` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived` | boolean | , default: false |
| `status` | integer | , default: 0 |
| `sequence` | integer | — |
| `restaurant_id` | bigint | — |
| `category` | string | , default: "general", null: false |

**Indexes:**
- `t.index ["restaurant_id", "category"], name: "index_sizes_on_restaurant_id_and_category"`
- `t.index ["restaurant_id", "status"], name: "index_sizes_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id"], name: "index_sizes_on_restaurant_id"`


---

### `tablesettings`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `status` | integer | — |
| `capacity` | integer | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `tabletype` | integer | — |
| `archived` | boolean | , default: false |
| `sequence` | integer | — |

**Indexes:**
- `t.index ["restaurant_id", "created_at"], name: "index_tablesettings_on_restaurant_created_at"`
- `t.index ["restaurant_id", "status"], name: "index_tablesettings_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id"], name: "index_tablesettings_on_restaurant_id"`


---

### `tags`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `typs` | integer | — |
| `archived` | boolean | , default: false |


---

### `taxes`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `taxtype` | integer | — |
| `taxpercentage` | float | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `sequence` | integer | — |
| `archived` | boolean | , default: false |
| `status` | integer | , default: 0 |

**Indexes:**
- `t.index ["restaurant_id", "status"], name: "index_taxes_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id"], name: "index_taxes_on_restaurant_id"`


---

### `tips`

| Column | Type | Options |
|---|---|---|
| `percentage` | float | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived` | boolean | , default: false |
| `sequence` | integer | — |
| `status` | integer | , default: 0 |

**Indexes:**
- `t.index ["restaurant_id", "status"], name: "index_tips_on_restaurant_status_active", where: "(archived = false)"`
- `t.index ["restaurant_id"], name: "index_tips_on_restaurant_id"`


---

### `userplans`

| Column | Type | Options |
|---|---|---|
| `user_id` | bigint | , null: false |
| `plan_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["plan_id"], name: "index_userplans_on_plan_id"`
- `t.index ["user_id"], name: "index_userplans_on_user_id"`


---

### `users`

| Column | Type | Options |
|---|---|---|
| `email` | string | , default: "", null: false |
| `encrypted_password` | string | , default: "", null: false |
| `reset_password_token` | string | — |
| `reset_password_sent_at` | datetime | — |
| `remember_created_at` | datetime | — |
| `first_name` | string | — |
| `last_name` | string | — |
| `announcements_last_read_at` | datetime | — |
| `admin` | boolean | , default: false, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `plan_id` | bigint | — |
| `confirmation_token` | string | — |
| `confirmed_at` | datetime | — |
| `confirmation_sent_at` | datetime | — |
| `unconfirmed_email` | string | — |
| `restaurants_count` | integer | , default: 0 |
| `employees_count` | integer | , default: 0 |
| `super_admin` | boolean | , default: false, null: false |
| `failed_attempts` | integer | , default: 0, null: false |
| `unlock_token` | string | — |
| `locked_at` | datetime | — |

**Indexes:**
- `t.index ["admin", "super_admin"], name: "index_users_on_admin_and_super_admin"`
- `t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true`
- `t.index ["email"], name: "index_users_on_email", unique: true`
- `t.index ["plan_id", "admin"], name: "index_users_on_plan_admin"`
- `t.index ["plan_id"], name: "index_users_on_plan_id"`
- `t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true`
- `t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true`



---

## 5. Other Tables (summary only)

`active_storage_attachments`, `active_storage_blobs`, `active_storage_variant_records`, `alcohol_order_events`, `alcohol_policies`, `announcements`, `beverage_pipeline_runs`, `contacts`, `crawl_source_rules`, `discovered_restaurants`, `explore_pages`, `features`, `features_plans`, `flavor_profiles`, `flipper_features`, `flipper_gates`, `friendly_id_slugs`, `genimages`, `hero_images`, `impersonation_audits`, `ingredients`, `local_guides`, `memory_metrics`, `menu_edit_sessions`, `menu_imports`, `menu_item_product_links`, `menu_items`, `menu_sections`, `menu_source_change_reviews`, `menu_sources`, `menu_versions`, `menuitem_ingredient_mappings`, `menuitem_size_mappings`, `menuitem_tag_mappings`, `menuitemlocales`, `menulocales`, `menuparticipants`, `menusectionlocales`, `metrics`, `noticed_events`, `noticed_notifications`, `ocr_menu_imports`, `ocr_menu_items`, `ocr_menu_sections`, `onboarding_sessions`, `order_events`, `ordr_split_payments`, `ordr_station_tickets`, `ordrparticipant_allergyn_filters`, `pairing_recommendations`, `pay_charges`, `pay_customers`, `pay_merchants`, `pay_payment_methods`, `pay_subscriptions`, `pay_webhooks`, `payment_attempts`, `payment_profiles`, `payment_refunds`, `performance_metrics`, `product_enrichments`, `products`, `provider_accounts`, `push_subscriptions`, `resource_locks`, `restaurant_claim_requests`, `restaurant_menus`, `restaurant_onboardings`, `restaurant_removal_requests`, `restaurant_subscriptions`, `restaurantavailabilities`, `restaurantlocales`, `services`, `similar_product_recommendations`, `slow_queries`, `smartmenus`, `staff_invitations`, `testimonials`, `tracks`, `user_sessions`, `voice_commands`, `whiskey_flights`

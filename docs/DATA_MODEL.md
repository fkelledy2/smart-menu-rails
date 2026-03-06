# Data Model

> **Auto-generated** by `bin/generate_docs` on 2026-03-05 23:30 UTC

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

## 4. Table Details

### `active_storage_attachments`

| Column | Type | Options |
|---|---|---|
| `name` | string | , null: false |
| `record_type` | string | , null: false |
| `record_id` | bigint | , null: false |
| `blob_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |

**Indexes:**
- `t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"`
- `t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true`


---

### `active_storage_blobs`

| Column | Type | Options |
|---|---|---|
| `key` | string | , null: false |
| `filename` | string | , null: false |
| `content_type` | string | — |
| `metadata` | text | — |
| `service_name` | string | , null: false |
| `byte_size` | bigint | , null: false |
| `checksum` | string | — |
| `created_at` | datetime | , null: false |

**Indexes:**
- `t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true`


---

### `active_storage_variant_records`

| Column | Type | Options |
|---|---|---|
| `blob_id` | bigint | , null: false |
| `variation_digest` | string | , null: false |

**Indexes:**
- `t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true`


---

### `alcohol_order_events`

| Column | Type | Options |
|---|---|---|
| `ordr_id` | bigint | , null: false |
| `ordritem_id` | bigint | , null: false |
| `menuitem_id` | bigint | , null: false |
| `restaurant_id` | bigint | , null: false |
| `employee_id` | integer | — |
| `customer_sessionid` | string | — |
| `alcoholic` | boolean | , default: false, null: false |
| `abv` | decimal | , precision: 5, scale: 2 |
| `alcohol_classification` | string | — |
| `age_check_acknowledged` | boolean | , default: false, null: false |
| `acknowledged_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["customer_sessionid"], name: "index_alcohol_order_events_on_customer_sessionid"`
- `t.index ["employee_id"], name: "index_alcohol_order_events_on_employee_id"`
- `t.index ["menuitem_id"], name: "index_alcohol_order_events_on_menuitem_id"`
- `t.index ["ordr_id", "age_check_acknowledged"], name: "index_alcohol_events_on_ordr_ack"`
- `t.index ["ordr_id"], name: "index_alcohol_order_events_on_ordr_id"`
- `t.index ["ordritem_id"], name: "index_alcohol_order_events_on_ordritem_id"`
- `t.index ["restaurant_id"], name: "index_alcohol_order_events_on_restaurant_id"`


---

### `alcohol_policies`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `allowed_days_of_week` | integer | , default: [], array: true |
| `allowed_time_ranges` | jsonb | , default: [] |
| `blackout_dates` | date | , default: [], array: true |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_alcohol_policies_on_restaurant_id"`


---

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

### `announcements`

| Column | Type | Options |
|---|---|---|
| `published_at` | datetime | — |
| `announcement_type` | string | — |
| `name` | string | — |
| `description` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |


---

### `beverage_pipeline_runs`

| Column | Type | Options |
|---|---|---|
| `menu_id` | bigint | , null: false |
| `restaurant_id` | bigint | , null: false |
| `status` | string | , default: "running", null: false |
| `current_step` | string | — |
| `error_summary` | text | — |
| `started_at` | datetime | — |
| `completed_at` | datetime | — |
| `items_processed` | integer | , default: 0, null: false |
| `needs_review_count` | integer | , default: 0, null: false |
| `unresolved_count` | integer | , default: 0, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menu_id", "status"], name: "index_beverage_pipeline_runs_on_menu_id_and_status"`
- `t.index ["menu_id"], name: "index_beverage_pipeline_runs_on_menu_id"`
- `t.index ["restaurant_id"], name: "index_beverage_pipeline_runs_on_restaurant_id"`


---

### `contacts`

| Column | Type | Options |
|---|---|---|
| `email` | string | — |
| `message` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["created_at"], name: "index_contacts_on_created_at"`
- `t.index ["email"], name: "index_contacts_on_email"`


---

### `crawl_source_rules`

| Column | Type | Options |
|---|---|---|
| `domain` | string | , null: false |
| `rule_type` | integer | , default: 0, null: false |
| `reason` | text | — |
| `created_by_user_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["created_by_user_id"], name: "index_crawl_source_rules_on_created_by_user_id"`
- `t.index ["domain"], name: "index_crawl_source_rules_on_domain", unique: true`
- `t.index ["rule_type"], name: "index_crawl_source_rules_on_rule_type"`


---

### `discovered_restaurants`

| Column | Type | Options |
|---|---|---|
| `city_name` | string | , null: false |
| `city_place_id` | string | — |
| `google_place_id` | string | , null: false |
| `name` | string | , null: false |
| `website_url` | string | — |
| `status` | integer | , default: 0, null: false |
| `confidence_score` | decimal | , precision: 5, scale: 4 |
| `discovered_at` | datetime | — |
| `description` | text | — |
| `metadata` | jsonb | , default: {} |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `restaurant_id` | bigint | — |
| `establishment_types` | string | , default: [], null: false, array: true |
| `address1` | string | — |
| `address2` | string | — |
| `city` | string | — |
| `state` | string | — |
| `postcode` | string | — |
| `country_code` | string | — |
| `currency` | string | — |
| `preferred_phone` | string | — |
| `preferred_email` | string | — |
| `image_context` | string | — |
| `image_style_profile` | text | — |

**Indexes:**
- `t.index ["city_name", "status", "discovered_at"], name: "idx_on_city_name_status_discovered_at_524af6544b"`
- `t.index ["country_code"], name: "index_discovered_restaurants_on_country_code"`
- `t.index ["google_place_id"], name: "index_discovered_restaurants_on_google_place_id", unique: true`
- `t.index ["restaurant_id"], name: "index_discovered_restaurants_on_restaurant_id"`


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

### `explore_pages`

| Column | Type | Options |
|---|---|---|
| `country_slug` | string | , null: false |
| `country_name` | string | , null: false |
| `city_slug` | string | , null: false |
| `city_name` | string | , null: false |
| `category_slug` | string | — |
| `category_name` | string | — |
| `restaurant_count` | integer | , default: 0, null: false |
| `meta_title` | text | — |
| `meta_description` | text | — |
| `last_refreshed_at` | datetime | — |
| `published` | boolean | , default: false, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["country_slug", "city_slug", "category_slug"], name: "idx_explore_pages_unique_path", unique: true`
- `t.index ["published"], name: "index_explore_pages_on_published"`
- `t.index ["restaurant_count"], name: "index_explore_pages_on_restaurant_count"`


---

### `features`

| Column | Type | Options |
|---|---|---|
| `key` | string | — |
| `descriptionKey` | string | — |
| `status` | integer | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |


---

### `features_plans`

| Column | Type | Options |
|---|---|---|
| `plan_id` | bigint | , null: false |
| `feature_id` | bigint | , null: false |
| `featurePlanNote` | string | — |
| `status` | integer | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["feature_id"], name: "index_features_plans_on_feature_id"`
- `t.index ["plan_id", "feature_id"], name: "index_features_plans_on_plan_id_and_feature_id", unique: true`
- `t.index ["plan_id"], name: "index_features_plans_on_plan_id"`


---

### `flavor_profiles`

| Column | Type | Options |
|---|---|---|
| `profilable_type` | string | , null: false |
| `profilable_id` | bigint | , null: false |
| `tags` | string | , default: [], null: false, array: true |
| `structure_metrics` | jsonb | , default: {}, null: false |
| `provenance` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["profilable_type", "profilable_id"], name: "idx_flavor_profiles_profilable", unique: true`
- `t.index ["profilable_type", "profilable_id"], name: "index_flavor_profiles_on_profilable"`
- `t.index ["tags"], name: "index_flavor_profiles_on_tags", using: :gin`


---

### `flipper_features`

| Column | Type | Options |
|---|---|---|
| `key` | string | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["key"], name: "index_flipper_features_on_key", unique: true`


---

### `flipper_gates`

| Column | Type | Options |
|---|---|---|
| `feature_key` | string | , null: false |
| `key` | string | , null: false |
| `value` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true`


---

### `friendly_id_slugs`

| Column | Type | Options |
|---|---|---|
| `slug` | string | , null: false |
| `sluggable_id` | integer | , null: false |
| `sluggable_type` | string | , limit: 50 |
| `scope` | string | — |
| `created_at` | datetime | — |

**Indexes:**
- `t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true`
- `t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"`
- `t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"`


---

### `genimages`

| Column | Type | Options |
|---|---|---|
| `image_data` | text | — |
| `name` | string | — |
| `description` | text | — |
| `restaurant_id` | bigint | , null: false |
| `menu_id` | bigint | — |
| `menusection_id` | bigint | — |
| `menuitem_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `prompt_fingerprint` | string | — |

**Indexes:**
- `t.index ["menu_id"], name: "index_genimages_on_menu_id"`
- `t.index ["menuitem_id"], name: "index_genimages_on_menuitem_id"`
- `t.index ["menusection_id"], name: "index_genimages_on_menusection_id"`
- `t.index ["prompt_fingerprint"], name: "index_genimages_on_prompt_fingerprint"`
- `t.index ["restaurant_id", "menu_id", "menuitem_id"], name: "index_genimages_on_restaurant_menu_item"`
- `t.index ["restaurant_id"], name: "index_genimages_on_restaurant_id"`


---

### `hero_images`

| Column | Type | Options |
|---|---|---|
| `image_url` | string | , null: false |
| `alt_text` | string | — |
| `sequence` | integer | , default: 0 |
| `status` | integer | , default: 0, null: false |
| `source_url` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["sequence"], name: "index_hero_images_on_sequence"`
- `t.index ["status"], name: "index_hero_images_on_status"`


---

### `impersonation_audits`

| Column | Type | Options |
|---|---|---|
| `admin_user_id` | bigint | , null: false |
| `impersonated_user_id` | bigint | , null: false |
| `started_at` | datetime | , null: false |
| `ended_at` | datetime | — |
| `expires_at` | datetime | , null: false |
| `ip_address` | string | — |
| `user_agent` | string | — |
| `ended_reason` | string | — |
| `reason` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["admin_user_id", "started_at"], name: "index_impersonation_audits_on_admin_user_id_and_started_at"`
- `t.index ["admin_user_id"], name: "index_impersonation_audits_on_admin_user_id"`
- `t.index ["expires_at"], name: "index_impersonation_audits_on_expires_at"`
- `t.index ["impersonated_user_id", "started_at"], name: "idx_on_impersonated_user_id_started_at_39d81181ba"`
- `t.index ["impersonated_user_id"], name: "index_impersonation_audits_on_impersonated_user_id"`


---

### `ingredients`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived` | boolean | , default: false |


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

### `local_guides`

| Column | Type | Options |
|---|---|---|
| `title` | string | , null: false |
| `slug` | string | , null: false |
| `city` | string | , null: false |
| `country` | string | , null: false |
| `category` | string | — |
| `content` | text | , null: false |
| `content_source` | text | — |
| `referenced_restaurants` | jsonb | , default: [] |
| `faq_data` | jsonb | , default: [] |
| `status` | integer | , default: 0, null: false |
| `published_at` | datetime | — |
| `regenerated_at` | datetime | — |
| `approved_by_user_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["approved_by_user_id"], name: "index_local_guides_on_approved_by_user_id"`
- `t.index ["city", "category"], name: "index_local_guides_on_city_and_category"`
- `t.index ["slug"], name: "index_local_guides_on_slug", unique: true`
- `t.index ["status"], name: "index_local_guides_on_status"`


---

### `memory_metrics`

| Column | Type | Options |
|---|---|---|
| `heap_size` | bigint | , null: false |
| `heap_free` | bigint | — |
| `objects_allocated` | bigint | — |
| `gc_count` | integer | — |
| `rss_memory` | bigint | — |
| `timestamp` | datetime | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["rss_memory", "timestamp"], name: "index_memory_metrics_on_rss_memory_and_timestamp"`
- `t.index ["timestamp"], name: "index_memory_metrics_on_timestamp"`


---

### `menu_edit_sessions`

| Column | Type | Options |
|---|---|---|
| `menu_id` | bigint | , null: false |
| `user_id` | bigint | , null: false |
| `session_id` | string | , null: false |
| `locked_fields` | json | , default: [] |
| `started_at` | datetime | — |
| `last_activity_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["last_activity_at"], name: "index_menu_edit_sessions_on_last_activity_at"`
- `t.index ["menu_id", "user_id"], name: "index_menu_edit_sessions_on_menu_id_and_user_id", unique: true`
- `t.index ["menu_id"], name: "index_menu_edit_sessions_on_menu_id"`
- `t.index ["session_id"], name: "index_menu_edit_sessions_on_session_id"`
- `t.index ["user_id"], name: "index_menu_edit_sessions_on_user_id"`


---

### `menu_imports`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `user_id` | bigint | , null: false |
| `status` | string | , default: "pending", null: false |
| `error_message` | text | — |
| `metadata` | jsonb | , default: {} |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["created_at"], name: "index_menu_imports_on_created_at"`
- `t.index ["restaurant_id"], name: "index_menu_imports_on_restaurant_id"`
- `t.index ["status"], name: "index_menu_imports_on_status"`
- `t.index ["user_id"], name: "index_menu_imports_on_user_id"`


---

### `menu_item_product_links`

| Column | Type | Options |
|---|---|---|
| `menuitem_id` | bigint | , null: false |
| `product_id` | bigint | , null: false |
| `resolution_confidence` | decimal | , precision: 5, scale: 4 |
| `explanations` | text | — |
| `locked` | boolean | , default: false, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menuitem_id", "product_id"], name: "index_menu_item_product_links_on_menuitem_id_and_product_id", unique: true`
- `t.index ["menuitem_id"], name: "index_menu_item_product_links_on_menuitem_id"`
- `t.index ["product_id"], name: "index_menu_item_product_links_on_product_id"`


---

### `menu_items`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `price` | decimal | — |
| `menu_section_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `position` | integer | — |
| `metadata` | jsonb | — |

**Indexes:**
- `t.index ["menu_section_id"], name: "index_menu_items_on_menu_section_id"`


---

### `menu_sections`

| Column | Type | Options |
|---|---|---|
| `name` | string | — |
| `description` | text | — |
| `position` | integer | — |
| `menu_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menu_id"], name: "index_menu_sections_on_menu_id"`


---

### `menu_source_change_reviews`

| Column | Type | Options |
|---|---|---|
| `menu_source_id` | bigint | , null: false |
| `status` | integer | , default: 0, null: false |
| `detected_at` | datetime | , null: false |
| `previous_fingerprint` | string | — |
| `new_fingerprint` | string | — |
| `previous_etag` | string | — |
| `new_etag` | string | — |
| `previous_last_modified` | datetime | — |
| `new_last_modified` | datetime | — |
| `notes` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `diff_content` | text | — |
| `diff_status` | integer | , default: 0, null: false |

**Indexes:**
- `t.index ["detected_at"], name: "index_menu_source_change_reviews_on_detected_at"`
- `t.index ["menu_source_id", "status"], name: "index_menu_source_change_reviews_on_menu_source_id_and_status"`
- `t.index ["menu_source_id"], name: "index_menu_source_change_reviews_on_menu_source_id"`


---

### `menu_sources`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | — |
| `discovered_restaurant_id` | bigint | — |
| `source_url` | string | , null: false |
| `source_type` | integer | , default: 0, null: false |
| `last_checked_at` | datetime | — |
| `last_fingerprint` | string | — |
| `etag` | string | — |
| `last_modified` | datetime | — |
| `status` | integer | , default: 0, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `name` | string | — |

**Indexes:**
- `t.index ["discovered_restaurant_id", "status"], name: "index_menu_sources_on_discovered_restaurant_id_and_status"`
- `t.index ["discovered_restaurant_id"], name: "index_menu_sources_on_discovered_restaurant_id"`
- `t.index ["restaurant_id", "status"], name: "index_menu_sources_on_restaurant_id_and_status"`
- `t.index ["restaurant_id"], name: "index_menu_sources_on_restaurant_id"`
- `t.index ["source_url"], name: "index_menu_sources_on_source_url"`


---

### `menu_versions`

| Column | Type | Options |
|---|---|---|
| `menu_id` | bigint | , null: false |
| `version_number` | integer | , null: false |
| `snapshot_json` | jsonb | , default: {}, null: false |
| `created_by_user_id` | bigint | — |
| `is_active` | boolean | , default: false, null: false |
| `starts_at` | datetime | — |
| `ends_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["created_by_user_id"], name: "index_menu_versions_on_created_by_user_id"`
- `t.index ["menu_id", "is_active"], name: "index_menu_versions_on_menu_id_and_is_active"`
- `t.index ["menu_id", "starts_at", "ends_at"], name: "index_menu_versions_on_menu_id_and_starts_at_and_ends_at"`
- `t.index ["menu_id", "version_number"], name: "index_menu_versions_on_menu_id_and_version_number", unique: true`
- `t.index ["menu_id"], name: "index_menu_versions_on_menu_id"`


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

### `menuitem_ingredient_mappings`

| Column | Type | Options |
|---|---|---|
| `menuitem_id` | bigint | , null: false |
| `ingredient_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["ingredient_id", "menuitem_id"], name: "index_menuitem_ingredient_on_ingredient_menuitem"`
- `t.index ["ingredient_id"], name: "index_menuitem_ingredient_mappings_on_ingredient_id"`
- `t.index ["menuitem_id"], name: "index_menuitem_ingredient_mappings_on_menuitem_id"`


---

### `menuitem_size_mappings`

| Column | Type | Options |
|---|---|---|
| `menuitem_id` | bigint | , null: false |
| `size_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `price` | float | , default: 0.0 |

**Indexes:**
- `t.index ["menuitem_id"], name: "index_menuitem_size_mappings_on_menuitem_id"`
- `t.index ["size_id", "menuitem_id"], name: "index_menuitem_size_on_size_menuitem"`
- `t.index ["size_id"], name: "index_menuitem_size_mappings_on_size_id"`


---

### `menuitem_tag_mappings`

| Column | Type | Options |
|---|---|---|
| `menuitem_id` | bigint | , null: false |
| `tag_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menuitem_id"], name: "index_menuitem_tag_mappings_on_menuitem_id"`
- `t.index ["tag_id", "menuitem_id"], name: "index_menuitem_tag_on_tag_menuitem"`
- `t.index ["tag_id"], name: "index_menuitem_tag_mappings_on_tag_id"`


---

### `menuitemlocales`

| Column | Type | Options |
|---|---|---|
| `locale` | string | — |
| `status` | integer | — |
| `name` | string | — |
| `description` | string | — |
| `menuitem_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menuitem_id", "locale", "status"], name: "index_menuitemlocales_on_menuitem_locale_status"`
- `t.index ["menuitem_id", "locale"], name: "index_menuitemlocales_on_menuitem_locale"`
- `t.index ["menuitem_id"], name: "index_menuitemlocales_on_menuitem_id"`


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

### `menulocales`

| Column | Type | Options |
|---|---|---|
| `locale` | string | — |
| `status` | integer | — |
| `name` | string | — |
| `description` | string | — |
| `menu_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menu_id", "locale"], name: "index_menulocales_on_menu_locale"`
- `t.index ["menu_id"], name: "index_menulocales_on_menu_id"`


---

### `menuparticipants`

| Column | Type | Options |
|---|---|---|
| `sessionid` | string | — |
| `preferredlocale` | string | — |
| `smartmenu_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["sessionid", "preferredlocale"], name: "index_menuparticipants_on_session_locale"`
- `t.index ["sessionid", "smartmenu_id"], name: "index_menuparticipants_on_session_smartmenu", unique: true`
- `t.index ["sessionid"], name: "index_menuparticipants_on_sessionid"`
- `t.index ["smartmenu_id"], name: "index_menuparticipants_on_smartmenu_id"`


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

### `menusectionlocales`

| Column | Type | Options |
|---|---|---|
| `locale` | string | — |
| `status` | integer | — |
| `name` | string | — |
| `description` | string | — |
| `menusection_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menusection_id", "locale"], name: "index_menusectionlocales_on_menusection_and_locale", unique: true`
- `t.index ["menusection_id", "status"], name: "index_menusectionlocales_on_menusection_status"`
- `t.index ["menusection_id"], name: "index_menusectionlocales_on_menusection_id"`


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

### `metrics`

| Column | Type | Options |
|---|---|---|
| `numberOfRestaurants` | integer | — |
| `numberOfMenus` | integer | — |
| `numberOfMenuItems` | integer | — |
| `numberOfOrders` | integer | — |
| `totalOrderValue` | float | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["created_at"], name: "index_metrics_on_created_at"`


---

### `noticed_events`

| Column | Type | Options |
|---|---|---|
| `type` | string | — |
| `record_type` | string | — |
| `record_id` | bigint | — |
| `params` | jsonb | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `notifications_count` | integer | — |

**Indexes:**
- `t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"`


---

### `noticed_notifications`

| Column | Type | Options |
|---|---|---|
| `type` | string | — |
| `event_id` | bigint | , null: false |
| `recipient_type` | string | , null: false |
| `recipient_id` | bigint | , null: false |
| `read_at` | datetime | , precision: nil |
| `seen_at` | datetime | , precision: nil |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["event_id"], name: "index_noticed_notifications_on_event_id"`
- `t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"`


---

### `ocr_menu_imports`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `name` | string | , null: false |
| `status` | string | , default: "pending", null: false |
| `error_message` | text | — |
| `total_pages` | integer | — |
| `processed_pages` | integer | , default: 0, null: false |
| `metadata` | jsonb | , default: {} |
| `menu_id` | bigint | — |
| `completed_at` | datetime | — |
| `failed_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `source_locale` | string | — |
| `ai_mode` | integer | , default: 0, null: false |

**Indexes:**
- `t.index ["menu_id"], name: "index_ocr_menu_imports_on_menu_id"`
- `t.index ["restaurant_id", "status", "created_at"], name: "index_ocr_imports_on_restaurant_status_created"`
- `t.index ["restaurant_id", "status"], name: "index_ocr_menu_imports_on_restaurant_and_status"`
- `t.index ["restaurant_id"], name: "index_ocr_menu_imports_on_restaurant_id"`
- `t.index ["source_locale"], name: "index_ocr_menu_imports_on_source_locale"`
- `t.index ["status"], name: "index_ocr_menu_imports_on_status"`


---

### `ocr_menu_items`

| Column | Type | Options |
|---|---|---|
| `ocr_menu_section_id` | bigint | , null: false |
| `name` | string | , null: false |
| `description` | text | — |
| `price` | decimal | , precision: 10, scale: 2 |
| `allergens` | text | , default: [], array: true |
| `sequence` | integer | , default: 0, null: false |
| `is_confirmed` | boolean | , default: false, null: false |
| `is_vegetarian` | boolean | , default: false |
| `is_vegan` | boolean | , default: false |
| `is_gluten_free` | boolean | , default: false |
| `metadata` | jsonb | , default: {} |
| `page_reference` | string | — |
| `menu_item_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `is_dairy_free` | boolean | , default: false, null: false |
| `menuitem_id` | bigint | — |
| `image_prompt` | text | — |

**Indexes:**
- `t.index ["allergens"], name: "index_ocr_menu_items_on_allergens", using: :gin`
- `t.index ["is_confirmed"], name: "index_ocr_menu_items_on_is_confirmed"`
- `t.index ["is_gluten_free"], name: "index_ocr_menu_items_on_is_gluten_free"`
- `t.index ["is_vegan"], name: "index_ocr_menu_items_on_is_vegan"`
- `t.index ["is_vegetarian"], name: "index_ocr_menu_items_on_is_vegetarian"`
- `t.index ["menu_item_id"], name: "index_ocr_menu_items_on_menu_item_id"`
- `t.index ["menuitem_id"], name: "index_ocr_menu_items_on_menuitem_id"`
- `t.index ["ocr_menu_section_id", "is_confirmed"], name: "index_ocr_menu_items_on_section_and_confirmed"`
- `t.index ["ocr_menu_section_id"], name: "index_ocr_menu_items_on_ocr_menu_section_id"`
- `t.index ["sequence"], name: "index_ocr_menu_items_on_sequence"`


---

### `ocr_menu_sections`

| Column | Type | Options |
|---|---|---|
| `ocr_menu_import_id` | bigint | , null: false |
| `name` | string | , null: false |
| `sequence` | integer | , default: 0, null: false |
| `metadata` | jsonb | , default: {} |
| `is_confirmed` | boolean | , default: false, null: false |
| `page_reference` | string | — |
| `menu_section_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `description` | text | — |
| `menusection_id` | bigint | — |

**Indexes:**
- `t.index ["is_confirmed"], name: "index_ocr_menu_sections_on_is_confirmed"`
- `t.index ["menu_section_id"], name: "index_ocr_menu_sections_on_menu_section_id"`
- `t.index ["menusection_id"], name: "index_ocr_menu_sections_on_menusection_id"`
- `t.index ["ocr_menu_import_id", "is_confirmed"], name: "index_ocr_menu_sections_on_import_and_confirmed"`
- `t.index ["ocr_menu_import_id"], name: "index_ocr_menu_sections_on_ocr_menu_import_id"`
- `t.index ["sequence"], name: "index_ocr_menu_sections_on_sequence"`


---

### `onboarding_sessions`

| Column | Type | Options |
|---|---|---|
| `user_id` | bigint | — |
| `status` | integer | , default: 0, null: false |
| `wizard_data` | text | — |
| `restaurant_id` | bigint | — |
| `menu_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["created_at"], name: "index_onboarding_sessions_on_created_at"`
- `t.index ["menu_id"], name: "index_onboarding_sessions_on_menu_id"`
- `t.index ["restaurant_id"], name: "index_onboarding_sessions_on_restaurant_id"`
- `t.index ["status"], name: "index_onboarding_sessions_on_status"`
- `t.index ["user_id"], name: "index_onboarding_sessions_on_user_id"`


---

### `order_events`

| Column | Type | Options |
|---|---|---|
| `ordr_id` | bigint | , null: false |
| `sequence` | bigint | , null: false |
| `event_type` | string | , null: false |
| `entity_type` | string | , null: false |
| `entity_id` | bigint | — |
| `payload` | jsonb | , default: {}, null: false |
| `source` | string | , null: false |
| `idempotency_key` | string | — |
| `occurred_at` | datetime | , default: -> { "CURRENT_TIMESTAMP" }, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["ordr_id", "created_at", "id"], name: "index_order_events_on_ordr_id_and_created_at_and_id"`
- `t.index ["ordr_id", "idempotency_key"], name: "index_order_events_on_ordr_id_and_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"`
- `t.index ["ordr_id", "sequence"], name: "index_order_events_on_ordr_id_and_sequence", unique: true`
- `t.index ["ordr_id"], name: "index_order_events_on_ordr_id"`


---

### `ordr_split_payments`

| Column | Type | Options |
|---|---|---|
| `ordr_id` | bigint | , null: false |
| `ordrparticipant_id` | bigint | — |
| `amount_cents` | integer | , null: false |
| `currency` | string | , null: false |
| `status` | integer | , default: 0, null: false |
| `provider_checkout_session_id` | string | — |
| `provider_payment_id` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `provider` | integer | , default: 0, null: false |
| `idempotency_key` | string | — |
| `tip_cents` | integer | , default: 0, null: false |
| `payer_ref` | string | — |

**Indexes:**
- `t.index ["idempotency_key"], name: "index_ordr_split_payments_on_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"`
- `t.index ["ordr_id"], name: "index_ordr_split_payments_on_ordr_id"`
- `t.index ["ordrparticipant_id"], name: "index_ordr_split_payments_on_ordrparticipant_id"`
- `t.index ["provider", "provider_payment_id"], name: "index_ordr_split_payments_on_provider_and_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"`
- `t.index ["provider_checkout_session_id"], name: "index_ordr_split_payments_on_provider_checkout_session_id", unique: true`
- `t.index ["provider_payment_id"], name: "index_ordr_split_payments_on_provider_payment_id"`


---

### `ordr_station_tickets`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `ordr_id` | bigint | , null: false |
| `station` | integer | , null: false |
| `status` | integer | , default: 20, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `sequence` | integer | , default: 1, null: false |
| `submitted_at` | datetime | — |

**Indexes:**
- `t.index ["ordr_id", "station", "sequence"], name: "index_station_tickets_on_order_station_sequence", unique: true`
- `t.index ["ordr_id"], name: "index_ordr_station_tickets_on_ordr_id"`
- `t.index ["restaurant_id", "station", "status"], name: "index_station_tickets_on_restaurant_station_status"`
- `t.index ["restaurant_id"], name: "index_ordr_station_tickets_on_restaurant_id"`


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

### `ordrparticipant_allergyn_filters`

| Column | Type | Options |
|---|---|---|
| `ordrparticipant_id` | bigint | , null: false |
| `allergyn_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["allergyn_id"], name: "index_ordrparticipant_allergyn_filters_on_allergyn_id"`
- `t.index ["ordrparticipant_id", "allergyn_id"], name: "index_ordrparticipant_allergyn_on_participant_allergyn"`
- `t.index ["ordrparticipant_id"], name: "index_ordrparticipant_allergyn_filters_on_ordrparticipant_id"`


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

### `pairing_recommendations`

| Column | Type | Options |
|---|---|---|
| `drink_menuitem_id` | bigint | , null: false |
| `food_menuitem_id` | bigint | , null: false |
| `complement_score` | decimal | , precision: 5, scale: 4, default: "0.0" |
| `contrast_score` | decimal | , precision: 5, scale: 4, default: "0.0" |
| `score` | decimal | , precision: 5, scale: 4, default: "0.0" |
| `rationale` | text | — |
| `risk_flags` | jsonb | , default: [], null: false |
| `pairing_type` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["drink_menuitem_id", "food_menuitem_id"], name: "idx_pairings_drink_food", unique: true`
- `t.index ["drink_menuitem_id"], name: "index_pairing_recommendations_on_drink_menuitem_id"`
- `t.index ["food_menuitem_id"], name: "index_pairing_recommendations_on_food_menuitem_id"`


---

### `pay_charges`

| Column | Type | Options |
|---|---|---|
| `customer_id` | bigint | , null: false |
| `subscription_id` | bigint | — |
| `processor_id` | string | , null: false |
| `amount` | integer | , null: false |
| `currency` | string | — |
| `application_fee_amount` | integer | — |
| `amount_refunded` | integer | — |
| `metadata` | jsonb | — |
| `data` | jsonb | — |
| `stripe_account` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `type` | string | — |

**Indexes:**
- `t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true`
- `t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"`


---

### `pay_customers`

| Column | Type | Options |
|---|---|---|
| `owner_type` | string | — |
| `owner_id` | bigint | — |
| `processor` | string | , null: false |
| `processor_id` | string | — |
| `default` | boolean | — |
| `data` | jsonb | — |
| `stripe_account` | string | — |
| `deleted_at` | datetime | , precision: nil |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `type` | string | — |

**Indexes:**
- `t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true`
- `t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true`


---

### `pay_merchants`

| Column | Type | Options |
|---|---|---|
| `owner_type` | string | — |
| `owner_id` | bigint | — |
| `processor` | string | , null: false |
| `processor_id` | string | — |
| `default` | boolean | — |
| `data` | jsonb | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `type` | string | — |

**Indexes:**
- `t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"`
- `t.index ["processor_id"], name: "index_pay_merchants_on_processor_id"`


---

### `pay_payment_methods`

| Column | Type | Options |
|---|---|---|
| `customer_id` | bigint | , null: false |
| `processor_id` | string | , null: false |
| `default` | boolean | — |
| `payment_method_type` | string | — |
| `data` | jsonb | — |
| `stripe_account` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `type` | string | — |

**Indexes:**
- `t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true`


---

### `pay_subscriptions`

| Column | Type | Options |
|---|---|---|
| `customer_id` | bigint | , null: false |
| `name` | string | , null: false |
| `processor_id` | string | , null: false |
| `processor_plan` | string | , null: false |
| `quantity` | integer | , default: 1, null: false |
| `status` | string | , null: false |
| `current_period_start` | datetime | , precision: nil |
| `current_period_end` | datetime | , precision: nil |
| `trial_ends_at` | datetime | , precision: nil |
| `ends_at` | datetime | , precision: nil |
| `metered` | boolean | — |
| `pause_behavior` | string | — |
| `pause_starts_at` | datetime | , precision: nil |
| `pause_resumes_at` | datetime | , precision: nil |
| `application_fee_percent` | decimal | , precision: 8, scale: 2 |
| `metadata` | jsonb | — |
| `data` | jsonb | — |
| `stripe_account` | string | — |
| `payment_method_id` | string | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `type` | string | — |

**Indexes:**
- `t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true`
- `t.index ["metered"], name: "index_pay_subscriptions_on_metered"`
- `t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"`
- `t.index ["payment_method_id"], name: "index_pay_subscriptions_on_payment_method_id"`


---

### `pay_webhooks`

| Column | Type | Options |
|---|---|---|
| `processor` | string | — |
| `event_type` | string | — |
| `event` | jsonb | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |


---

### `payment_attempts`

| Column | Type | Options |
|---|---|---|
| `ordr_id` | bigint | , null: false |
| `restaurant_id` | bigint | , null: false |
| `provider` | integer | , default: 0, null: false |
| `provider_payment_id` | string | — |
| `amount_cents` | integer | , null: false |
| `currency` | string | , null: false |
| `status` | integer | , default: 0, null: false |
| `charge_pattern` | integer | , default: 0, null: false |
| `merchant_model` | integer | , default: 0, null: false |
| `platform_fee_cents` | integer | — |
| `provider_fee_cents` | integer | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `idempotency_key` | string | — |
| `tip_cents` | integer | , default: 0, null: false |
| `provider_checkout_url` | string | — |

**Indexes:**
- `t.index ["idempotency_key"], name: "index_payment_attempts_on_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"`
- `t.index ["ordr_id", "created_at"], name: "index_payment_attempts_on_ordr_id_and_created_at"`
- `t.index ["ordr_id"], name: "index_payment_attempts_on_ordr_id"`
- `t.index ["provider", "provider_payment_id"], name: "index_payment_attempts_on_provider_and_provider_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"`
- `t.index ["restaurant_id", "created_at"], name: "index_payment_attempts_on_restaurant_id_and_created_at"`
- `t.index ["restaurant_id"], name: "index_payment_attempts_on_restaurant_id"`


---

### `payment_profiles`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `merchant_model` | integer | , default: 0, null: false |
| `primary_provider` | integer | , default: 0, null: false |
| `fallback_providers` | jsonb | , default: {}, null: false |
| `default_country` | string | — |
| `default_currency` | string | — |
| `fee_model` | jsonb | , default: {}, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_payment_profiles_on_restaurant_id", unique: true`


---

### `payment_refunds`

| Column | Type | Options |
|---|---|---|
| `payment_attempt_id` | bigint | , null: false |
| `ordr_id` | bigint | , null: false |
| `restaurant_id` | bigint | , null: false |
| `provider` | integer | , default: 0, null: false |
| `provider_refund_id` | string | — |
| `amount_cents` | integer | — |
| `currency` | string | — |
| `status` | integer | , default: 0, null: false |
| `provider_response_payload` | jsonb | , default: {}, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["ordr_id"], name: "index_payment_refunds_on_ordr_id"`
- `t.index ["payment_attempt_id", "created_at"], name: "index_payment_refunds_on_payment_attempt_id_and_created_at"`
- `t.index ["payment_attempt_id"], name: "index_payment_refunds_on_payment_attempt_id"`
- `t.index ["provider", "provider_refund_id"], name: "index_payment_refunds_on_provider_and_provider_refund_id", unique: true, where: "(provider_refund_id IS NOT NULL)"`
- `t.index ["restaurant_id"], name: "index_payment_refunds_on_restaurant_id"`


---

### `performance_metrics`

| Column | Type | Options |
|---|---|---|
| `endpoint` | string | , null: false |
| `response_time` | float | , null: false |
| `memory_usage` | integer | — |
| `status_code` | integer | , null: false |
| `user_id` | bigint | — |
| `controller` | string | — |
| `action` | string | — |
| `timestamp` | datetime | , null: false |
| `additional_data` | json | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["endpoint", "timestamp"], name: "index_performance_metrics_on_endpoint_and_timestamp"`
- `t.index ["response_time"], name: "index_performance_metrics_on_response_time"`
- `t.index ["status_code", "timestamp"], name: "index_performance_metrics_on_status_code_and_timestamp"`
- `t.index ["timestamp"], name: "index_performance_metrics_on_timestamp"`
- `t.index ["user_id"], name: "index_performance_metrics_on_user_id"`


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

### `product_enrichments`

| Column | Type | Options |
|---|---|---|
| `product_id` | bigint | , null: false |
| `source` | string | , null: false |
| `external_id` | string | — |
| `payload_json` | jsonb | , default: {}, null: false |
| `fetched_at` | datetime | — |
| `expires_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["product_id", "source"], name: "index_product_enrichments_on_product_id_and_source"`
- `t.index ["product_id"], name: "index_product_enrichments_on_product_id"`
- `t.index ["source", "external_id"], name: "index_product_enrichments_on_source_and_external_id"`


---

### `products`

| Column | Type | Options |
|---|---|---|
| `product_type` | string | , null: false |
| `canonical_name` | string | , null: false |
| `attributes_json` | jsonb | , default: {}, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["product_type", "canonical_name"], name: "index_products_on_product_type_and_canonical_name", unique: true`


---

### `provider_accounts`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `provider` | integer | , default: 0, null: false |
| `provider_account_id` | string | — |
| `account_type` | string | — |
| `country` | string | — |
| `currency` | string | — |
| `status` | integer | , default: 0, null: false |
| `capabilities` | jsonb | , default: {}, null: false |
| `payouts_enabled` | boolean | , default: false, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `access_token` | text | — |
| `refresh_token` | text | — |
| `token_expires_at` | datetime | — |
| `environment` | string | , default: "production", null: false |
| `scopes` | text | — |
| `connected_at` | datetime | — |
| `disconnected_at` | datetime | — |

**Indexes:**
- `t.index ["provider", "provider_account_id"], name: "index_provider_accounts_on_provider_and_provider_account_id", unique: true`
- `t.index ["restaurant_id", "provider"], name: "index_provider_accounts_on_restaurant_id_and_provider"`
- `t.index ["restaurant_id"], name: "index_provider_accounts_on_restaurant_id"`


---

### `push_subscriptions`

| Column | Type | Options |
|---|---|---|
| `user_id` | bigint | , null: false |
| `endpoint` | string | , null: false |
| `p256dh_key` | text | , null: false |
| `auth_key` | text | , null: false |
| `active` | boolean | , default: true, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true`
- `t.index ["user_id", "active"], name: "index_push_subscriptions_on_user_id_and_active"`
- `t.index ["user_id"], name: "index_push_subscriptions_on_user_id"`


---

### `resource_locks`

| Column | Type | Options |
|---|---|---|
| `resource_type` | string | , null: false |
| `resource_id` | bigint | , null: false |
| `field_name` | string | — |
| `user_id` | bigint | , null: false |
| `session_id` | string | , null: false |
| `acquired_at` | datetime | — |
| `expires_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["expires_at"], name: "index_resource_locks_on_expires_at"`
- `t.index ["resource_type", "resource_id", "field_name"], name: "index_resource_locks_on_resource_and_field", unique: true`
- `t.index ["session_id"], name: "index_resource_locks_on_session_id"`
- `t.index ["user_id"], name: "index_resource_locks_on_user_id"`


---

### `restaurant_claim_requests`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `initiated_by_user_id` | bigint | — |
| `status` | integer | , default: 0, null: false |
| `verification_method` | integer | , default: 0, null: false |
| `claimant_email` | string | , null: false |
| `claimant_name` | string | — |
| `evidence` | text | — |
| `review_notes` | text | — |
| `verified_at` | datetime | — |
| `reviewed_by_user_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["initiated_by_user_id"], name: "index_restaurant_claim_requests_on_initiated_by_user_id"`
- `t.index ["restaurant_id", "status"], name: "index_restaurant_claim_requests_on_restaurant_id_and_status"`
- `t.index ["restaurant_id"], name: "index_restaurant_claim_requests_on_restaurant_id"`
- `t.index ["reviewed_by_user_id"], name: "index_restaurant_claim_requests_on_reviewed_by_user_id"`


---

### `restaurant_menus`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `menu_id` | bigint | , null: false |
| `sequence` | integer | — |
| `status` | integer | , default: 1, null: false |
| `availability_override_enabled` | boolean | , default: false, null: false |
| `availability_state` | integer | , default: 0, null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `archived_at` | datetime | — |
| `archived_reason` | string | — |
| `archived_by_id` | bigint | — |

**Indexes:**
- `t.index ["archived_by_id"], name: "index_restaurant_menus_on_archived_by_id"`
- `t.index ["menu_id"], name: "index_restaurant_menus_on_menu_id"`
- `t.index ["restaurant_id", "menu_id"], name: "index_restaurant_menus_on_restaurant_id_and_menu_id", unique: true`
- `t.index ["restaurant_id"], name: "index_restaurant_menus_on_restaurant_id"`


---

### `restaurant_onboardings`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `status` | integer | , default: 0 |
| `progress_steps` | jsonb | , default: {} |
| `completed_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_restaurant_onboardings_on_restaurant_id"`


---

### `restaurant_removal_requests`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `requested_by_email` | string | , null: false |
| `source` | integer | , default: 0, null: false |
| `status` | integer | , default: 0, null: false |
| `reason` | text | — |
| `admin_notes` | text | — |
| `actioned_at` | datetime | — |
| `actioned_by_user_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["actioned_by_user_id"], name: "index_restaurant_removal_requests_on_actioned_by_user_id"`
- `t.index ["restaurant_id", "status"], name: "index_restaurant_removal_requests_on_restaurant_id_and_status"`
- `t.index ["restaurant_id"], name: "index_restaurant_removal_requests_on_restaurant_id"`


---

### `restaurant_subscriptions`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `status` | integer | , default: 0, null: false |
| `stripe_customer_id` | string | — |
| `stripe_subscription_id` | string | — |
| `payment_method_on_file` | boolean | , default: false, null: false |
| `trial_ends_at` | datetime | — |
| `current_period_end` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_restaurant_subscriptions_on_restaurant_id", unique: true`
- `t.index ["stripe_customer_id"], name: "index_restaurant_subscriptions_on_stripe_customer_id"`
- `t.index ["stripe_subscription_id"], name: "index_restaurant_subscriptions_on_stripe_subscription_id"`


---

### `restaurantavailabilities`

| Column | Type | Options |
|---|---|---|
| `dayofweek` | integer | — |
| `starthour` | integer | — |
| `startmin` | integer | — |
| `endhour` | integer | — |
| `endmin` | integer | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `status` | integer | — |
| `sequence` | integer | — |
| `archived` | boolean | , default: false |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_restaurantavailabilities_on_restaurant_id"`


---

### `restaurantlocales`

| Column | Type | Options |
|---|---|---|
| `locale` | string | — |
| `status` | integer | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `dfault` | boolean | — |
| `sequence` | integer | , default: 0, null: false |

**Indexes:**
- `t.index ["restaurant_id", "locale"], name: "index_restaurantlocales_on_restaurant_locale"`
- `t.index ["restaurant_id", "sequence"], name: "index_restaurantlocales_on_restaurant_id_and_sequence"`
- `t.index ["restaurant_id", "status", "dfault"], name: "index_restaurantlocales_on_restaurant_status_default"`
- `t.index ["restaurant_id"], name: "index_restaurantlocales_on_restaurant_id"`


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

### `services`

| Column | Type | Options |
|---|---|---|
| `user_id` | bigint | , null: false |
| `provider` | string | — |
| `uid` | string | — |
| `access_token` | string | — |
| `access_token_secret` | string | — |
| `refresh_token` | string | — |
| `expires_at` | datetime | — |
| `auth` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["user_id"], name: "index_services_on_user_id"`


---

### `similar_product_recommendations`

| Column | Type | Options |
|---|---|---|
| `product_id` | bigint | , null: false |
| `recommended_product_id` | bigint | , null: false |
| `score` | decimal | , precision: 5, scale: 4, default: "0.0" |
| `rationale` | text | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["product_id", "recommended_product_id"], name: "idx_similar_products_pair", unique: true`
- `t.index ["product_id"], name: "index_similar_product_recommendations_on_product_id"`
- `t.index ["recommended_product_id"], name: "idx_on_recommended_product_id_d9294a2c90"`


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

### `slow_queries`

| Column | Type | Options |
|---|---|---|
| `sql` | text | , null: false |
| `duration` | float | , null: false |
| `query_name` | string | — |
| `backtrace` | text | — |
| `timestamp` | datetime | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["duration", "timestamp"], name: "index_slow_queries_on_duration_and_timestamp"`
- `t.index ["timestamp"], name: "index_slow_queries_on_timestamp"`


---

### `smartmenus`

| Column | Type | Options |
|---|---|---|
| `slug` | string | , null: false |
| `restaurant_id` | bigint | , null: false |
| `menu_id` | bigint | — |
| `tablesetting_id` | bigint | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menu_id"], name: "index_smartmenus_on_menu_id"`
- `t.index ["restaurant_id", "menu_id", "tablesetting_id"], name: "uniq_smartmenus_restaurant_menu_table", unique: true, where: "((menu_id IS NOT NULL) AND (tablesetting_id IS NOT NULL))"`
- `t.index ["restaurant_id", "menu_id"], name: "uniq_smartmenus_restaurant_menu_global", unique: true, where: "((tablesetting_id IS NULL) AND (menu_id IS NOT NULL))"`
- `t.index ["restaurant_id", "slug"], name: "index_smartmenus_on_restaurant_slug"`
- `t.index ["restaurant_id", "tablesetting_id"], name: "uniq_smartmenus_restaurant_table_general", unique: true, where: "((menu_id IS NULL) AND (tablesetting_id IS NOT NULL))"`
- `t.index ["restaurant_id"], name: "index_smartmenus_on_restaurant_id"`
- `t.index ["slug"], name: "index_smartmenus_on_slug"`
- `t.index ["tablesetting_id"], name: "index_smartmenus_on_tablesetting_id"`


---

### `staff_invitations`

| Column | Type | Options |
|---|---|---|
| `restaurant_id` | bigint | , null: false |
| `invited_by_id` | bigint | , null: false |
| `email` | string | , null: false |
| `role` | integer | , default: 0, null: false |
| `token` | string | , null: false |
| `status` | integer | , default: 0, null: false |
| `accepted_at` | datetime | — |
| `expires_at` | datetime | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["invited_by_id"], name: "index_staff_invitations_on_invited_by_id"`
- `t.index ["restaurant_id", "email"], name: "idx_staff_invitations_restaurant_email"`
- `t.index ["restaurant_id"], name: "index_staff_invitations_on_restaurant_id"`
- `t.index ["status"], name: "index_staff_invitations_on_status"`
- `t.index ["token"], name: "index_staff_invitations_on_token", unique: true`


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

### `testimonials`

| Column | Type | Options |
|---|---|---|
| `sequence` | integer | — |
| `status` | integer | — |
| `testimonial` | string | — |
| `user_id` | bigint | , null: false |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_testimonials_on_restaurant_id"`
- `t.index ["user_id"], name: "index_testimonials_on_user_id"`


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

### `tracks`

| Column | Type | Options |
|---|---|---|
| `externalid` | string | — |
| `name` | string | — |
| `description` | text | — |
| `image` | string | — |
| `sequence` | integer | — |
| `restaurant_id` | bigint | , null: false |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |
| `artist` | string | — |
| `explicit` | boolean | — |
| `is_playable` | boolean | — |
| `status` | integer | — |

**Indexes:**
- `t.index ["restaurant_id"], name: "index_tracks_on_restaurant_id"`


---

### `user_sessions`

| Column | Type | Options |
|---|---|---|
| `user_id` | bigint | , null: false |
| `session_id` | string | , null: false |
| `resource_type` | string | — |
| `resource_id` | bigint | — |
| `status` | string | , default: "active", null: false |
| `last_activity_at` | datetime | — |
| `metadata` | json | , default: {} |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["last_activity_at"], name: "index_user_sessions_on_last_activity_at"`
- `t.index ["resource_type", "resource_id"], name: "index_user_sessions_on_resource_type_and_resource_id"`
- `t.index ["session_id"], name: "index_user_sessions_on_session_id", unique: true`
- `t.index ["user_id", "status"], name: "index_user_sessions_on_user_id_and_status"`
- `t.index ["user_id"], name: "index_user_sessions_on_user_id"`


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

### `voice_commands`

| Column | Type | Options |
|---|---|---|
| `smartmenu_id` | bigint | , null: false |
| `session_id` | string | , null: false |
| `status` | string | , default: "queued", null: false |
| `locale` | string | — |
| `transcript` | text | — |
| `intent` | jsonb | — |
| `result` | jsonb | — |
| `error_message` | text | — |
| `context` | jsonb | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["smartmenu_id", "session_id", "created_at"], name: "idx_on_smartmenu_id_session_id_created_at_dc50bab09c"`
- `t.index ["smartmenu_id"], name: "index_voice_commands_on_smartmenu_id"`
- `t.index ["status"], name: "index_voice_commands_on_status"`


---

### `whiskey_flights`

| Column | Type | Options |
|---|---|---|
| `menu_id` | bigint | , null: false |
| `theme_key` | string | , null: false |
| `title` | string | , null: false |
| `narrative` | text | — |
| `items` | jsonb | , default: [], null: false |
| `source` | string | , default: "ai", null: false |
| `status` | string | , default: "draft", null: false |
| `total_price` | float | — |
| `custom_price` | float | — |
| `generated_at` | datetime | — |
| `created_at` | datetime | , null: false |
| `updated_at` | datetime | , null: false |

**Indexes:**
- `t.index ["menu_id", "theme_key"], name: "index_whiskey_flights_on_menu_id_and_theme_key", unique: true`
- `t.index ["menu_id"], name: "index_whiskey_flights_on_menu_id"`
- `t.index ["status"], name: "index_whiskey_flights_on_status"`



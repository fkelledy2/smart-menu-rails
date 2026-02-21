# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_20_213701) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alcohol_order_events", force: :cascade do |t|
    t.bigint "ordr_id", null: false
    t.bigint "ordritem_id", null: false
    t.bigint "menuitem_id", null: false
    t.bigint "restaurant_id", null: false
    t.integer "employee_id"
    t.string "customer_sessionid"
    t.boolean "alcoholic", default: false, null: false
    t.decimal "abv", precision: 5, scale: 2
    t.string "alcohol_classification"
    t.boolean "age_check_acknowledged", default: false, null: false
    t.datetime "acknowledged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_sessionid"], name: "index_alcohol_order_events_on_customer_sessionid"
    t.index ["employee_id"], name: "index_alcohol_order_events_on_employee_id"
    t.index ["menuitem_id"], name: "index_alcohol_order_events_on_menuitem_id"
    t.index ["ordr_id", "age_check_acknowledged"], name: "index_alcohol_events_on_ordr_ack"
    t.index ["ordr_id"], name: "index_alcohol_order_events_on_ordr_id"
    t.index ["ordritem_id"], name: "index_alcohol_order_events_on_ordritem_id"
    t.index ["restaurant_id"], name: "index_alcohol_order_events_on_restaurant_id"
  end

  create_table "alcohol_policies", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.integer "allowed_days_of_week", default: [], array: true
    t.jsonb "allowed_time_ranges", default: []
    t.date "blackout_dates", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_alcohol_policies_on_restaurant_id"
  end

  create_table "allergyns", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "symbol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "status", default: 0
    t.integer "sequence"
    t.bigint "restaurant_id"
    t.index ["restaurant_id", "status"], name: "index_allergyns_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id"], name: "index_allergyns_on_restaurant_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.datetime "published_at"
    t.string "announcement_type"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "beverage_pipeline_runs", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.bigint "restaurant_id", null: false
    t.string "status", default: "running", null: false
    t.string "current_step"
    t.text "error_summary"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "items_processed", default: 0, null: false
    t.integer "needs_review_count", default: 0, null: false
    t.integer "unresolved_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id", "status"], name: "index_beverage_pipeline_runs_on_menu_id_and_status"
    t.index ["menu_id"], name: "index_beverage_pipeline_runs_on_menu_id"
    t.index ["restaurant_id"], name: "index_beverage_pipeline_runs_on_restaurant_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "email"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["email"], name: "index_contacts_on_email"
  end

  create_table "crawl_source_rules", force: :cascade do |t|
    t.string "domain", null: false
    t.integer "rule_type", default: 0, null: false
    t.text "reason"
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_crawl_source_rules_on_created_by_user_id"
    t.index ["domain"], name: "index_crawl_source_rules_on_domain", unique: true
    t.index ["rule_type"], name: "index_crawl_source_rules_on_rule_type"
  end

  create_table "discovered_restaurants", force: :cascade do |t|
    t.string "city_name", null: false
    t.string "city_place_id"
    t.string "google_place_id", null: false
    t.string "name", null: false
    t.string "website_url"
    t.integer "status", default: 0, null: false
    t.decimal "confidence_score", precision: 5, scale: 4
    t.datetime "discovered_at"
    t.text "description"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.string "establishment_types", default: [], null: false, array: true
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country_code"
    t.string "currency"
    t.string "preferred_phone"
    t.string "preferred_email"
    t.string "image_context"
    t.text "image_style_profile"
    t.index ["city_name", "status", "discovered_at"], name: "idx_on_city_name_status_discovered_at_524af6544b"
    t.index ["country_code"], name: "index_discovered_restaurants_on_country_code"
    t.index ["google_place_id"], name: "index_discovered_restaurants_on_google_place_id", unique: true
    t.index ["restaurant_id"], name: "index_discovered_restaurants_on_restaurant_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "eid"
    t.string "image"
    t.integer "status"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.string "email"
    t.bigint "user_id", null: false
    t.boolean "archived", default: false
    t.integer "sequence"
    t.index ["email"], name: "index_employees_on_email"
    t.index ["restaurant_id", "created_at"], name: "index_employees_on_restaurant_created_at"
    t.index ["restaurant_id", "role", "status"], name: "index_employees_on_restaurant_role_status", where: "(archived = false)"
    t.index ["restaurant_id", "status"], name: "index_employees_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id"], name: "index_employees_on_restaurant_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "explore_pages", force: :cascade do |t|
    t.string "country_slug", null: false
    t.string "country_name", null: false
    t.string "city_slug", null: false
    t.string "city_name", null: false
    t.string "category_slug"
    t.string "category_name"
    t.integer "restaurant_count", default: 0, null: false
    t.text "meta_title"
    t.text "meta_description"
    t.datetime "last_refreshed_at"
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_slug", "city_slug", "category_slug"], name: "idx_explore_pages_unique_path", unique: true
    t.index ["published"], name: "index_explore_pages_on_published"
    t.index ["restaurant_count"], name: "index_explore_pages_on_restaurant_count"
  end

  create_table "features", force: :cascade do |t|
    t.string "key"
    t.string "descriptionKey"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "features_plans", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "feature_id", null: false
    t.string "featurePlanNote"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_id"], name: "index_features_plans_on_feature_id"
    t.index ["plan_id", "feature_id"], name: "index_features_plans_on_plan_id_and_feature_id", unique: true
    t.index ["plan_id"], name: "index_features_plans_on_plan_id"
  end

  create_table "flavor_profiles", force: :cascade do |t|
    t.string "profilable_type", null: false
    t.bigint "profilable_id", null: false
    t.string "tags", default: [], null: false, array: true
    t.jsonb "structure_metrics", default: {}, null: false
    t.string "provenance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profilable_type", "profilable_id"], name: "idx_flavor_profiles_profilable", unique: true
    t.index ["profilable_type", "profilable_id"], name: "index_flavor_profiles_on_profilable"
    t.index ["tags"], name: "index_flavor_profiles_on_tags", using: :gin
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "genimages", force: :cascade do |t|
    t.text "image_data"
    t.string "name"
    t.text "description"
    t.bigint "restaurant_id", null: false
    t.bigint "menu_id"
    t.bigint "menusection_id"
    t.bigint "menuitem_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "prompt_fingerprint"
    t.index ["menu_id"], name: "index_genimages_on_menu_id"
    t.index ["menuitem_id"], name: "index_genimages_on_menuitem_id"
    t.index ["menusection_id"], name: "index_genimages_on_menusection_id"
    t.index ["prompt_fingerprint"], name: "index_genimages_on_prompt_fingerprint"
    t.index ["restaurant_id", "menu_id", "menuitem_id"], name: "index_genimages_on_restaurant_menu_item"
    t.index ["restaurant_id"], name: "index_genimages_on_restaurant_id"
  end

  create_table "hero_images", force: :cascade do |t|
    t.string "image_url", null: false
    t.string "alt_text"
    t.integer "sequence", default: 0
    t.integer "status", default: 0, null: false
    t.string "source_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sequence"], name: "index_hero_images_on_sequence"
    t.index ["status"], name: "index_hero_images_on_status"
  end

  create_table "impersonation_audits", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.bigint "impersonated_user_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "ended_reason"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "started_at"], name: "index_impersonation_audits_on_admin_user_id_and_started_at"
    t.index ["admin_user_id"], name: "index_impersonation_audits_on_admin_user_id"
    t.index ["expires_at"], name: "index_impersonation_audits_on_expires_at"
    t.index ["impersonated_user_id", "started_at"], name: "idx_on_impersonated_user_id_started_at_39d81181ba"
    t.index ["impersonated_user_id"], name: "index_impersonation_audits_on_impersonated_user_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
  end

  create_table "inventories", force: :cascade do |t|
    t.integer "startinginventory"
    t.integer "currentinventory"
    t.integer "resethour"
    t.bigint "menuitem_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "status", default: 0
    t.integer "sequence"
    t.index ["archived"], name: "index_inventories_on_archived"
    t.index ["menuitem_id", "status"], name: "index_inventories_on_menuitem_status_active", where: "(archived = false)"
    t.index ["menuitem_id", "updated_at"], name: "index_inventories_on_menuitem_updated_at"
    t.index ["menuitem_id"], name: "index_inventories_on_menuitem_id"
    t.index ["status"], name: "index_inventories_on_status"
  end

  create_table "ledger_events", force: :cascade do |t|
    t.integer "entity_type", default: 0, null: false
    t.bigint "entity_id"
    t.integer "event_type", default: 0, null: false
    t.integer "amount_cents"
    t.string "currency"
    t.integer "provider", default: 0, null: false
    t.string "provider_event_id", null: false
    t.string "provider_event_type"
    t.jsonb "raw_event_payload", default: {}, null: false
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type", "entity_id"], name: "index_ledger_events_on_entity_type_and_entity_id"
    t.index ["occurred_at"], name: "index_ledger_events_on_occurred_at"
    t.index ["provider", "provider_event_id"], name: "index_ledger_events_on_provider_and_provider_event_id", unique: true
  end

  create_table "local_guides", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "city", null: false
    t.string "country", null: false
    t.string "category"
    t.text "content", null: false
    t.text "content_source"
    t.jsonb "referenced_restaurants", default: []
    t.jsonb "faq_data", default: []
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.datetime "regenerated_at"
    t.bigint "approved_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_user_id"], name: "index_local_guides_on_approved_by_user_id"
    t.index ["city", "category"], name: "index_local_guides_on_city_and_category"
    t.index ["slug"], name: "index_local_guides_on_slug", unique: true
    t.index ["status"], name: "index_local_guides_on_status"
  end

  create_table "memory_metrics", force: :cascade do |t|
    t.bigint "heap_size", null: false
    t.bigint "heap_free"
    t.bigint "objects_allocated"
    t.integer "gc_count"
    t.bigint "rss_memory"
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rss_memory", "timestamp"], name: "index_memory_metrics_on_rss_memory_and_timestamp"
    t.index ["timestamp"], name: "index_memory_metrics_on_timestamp"
  end

  create_table "menu_edit_sessions", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.bigint "user_id", null: false
    t.string "session_id", null: false
    t.json "locked_fields", default: []
    t.datetime "started_at"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_activity_at"], name: "index_menu_edit_sessions_on_last_activity_at"
    t.index ["menu_id", "user_id"], name: "index_menu_edit_sessions_on_menu_id_and_user_id", unique: true
    t.index ["menu_id"], name: "index_menu_edit_sessions_on_menu_id"
    t.index ["session_id"], name: "index_menu_edit_sessions_on_session_id"
    t.index ["user_id"], name: "index_menu_edit_sessions_on_user_id"
  end

  create_table "menu_imports", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_menu_imports_on_created_at"
    t.index ["restaurant_id"], name: "index_menu_imports_on_restaurant_id"
    t.index ["status"], name: "index_menu_imports_on_status"
    t.index ["user_id"], name: "index_menu_imports_on_user_id"
  end

  create_table "menu_item_product_links", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "product_id", null: false
    t.decimal "resolution_confidence", precision: 5, scale: 4
    t.text "explanations"
    t.boolean "locked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menuitem_id", "product_id"], name: "index_menu_item_product_links_on_menuitem_id_and_product_id", unique: true
    t.index ["menuitem_id"], name: "index_menu_item_product_links_on_menuitem_id"
    t.index ["product_id"], name: "index_menu_item_product_links_on_product_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.bigint "menu_section_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.jsonb "metadata"
    t.index ["menu_section_id"], name: "index_menu_items_on_menu_section_id"
  end

  create_table "menu_sections", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "position"
    t.bigint "menu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_menu_sections_on_menu_id"
  end

  create_table "menu_source_change_reviews", force: :cascade do |t|
    t.bigint "menu_source_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "detected_at", null: false
    t.string "previous_fingerprint"
    t.string "new_fingerprint"
    t.string "previous_etag"
    t.string "new_etag"
    t.datetime "previous_last_modified"
    t.datetime "new_last_modified"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "diff_content"
    t.integer "diff_status", default: 0, null: false
    t.index ["detected_at"], name: "index_menu_source_change_reviews_on_detected_at"
    t.index ["menu_source_id", "status"], name: "index_menu_source_change_reviews_on_menu_source_id_and_status"
    t.index ["menu_source_id"], name: "index_menu_source_change_reviews_on_menu_source_id"
  end

  create_table "menu_sources", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.bigint "discovered_restaurant_id"
    t.string "source_url", null: false
    t.integer "source_type", default: 0, null: false
    t.datetime "last_checked_at"
    t.string "last_fingerprint"
    t.string "etag"
    t.datetime "last_modified"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["discovered_restaurant_id", "status"], name: "index_menu_sources_on_discovered_restaurant_id_and_status"
    t.index ["discovered_restaurant_id"], name: "index_menu_sources_on_discovered_restaurant_id"
    t.index ["restaurant_id", "status"], name: "index_menu_sources_on_restaurant_id_and_status"
    t.index ["restaurant_id"], name: "index_menu_sources_on_restaurant_id"
    t.index ["source_url"], name: "index_menu_sources_on_source_url"
  end

  create_table "menu_versions", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.integer "version_number", null: false
    t.jsonb "snapshot_json", default: {}, null: false
    t.bigint "created_by_user_id"
    t.boolean "is_active", default: false, null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_menu_versions_on_created_by_user_id"
    t.index ["menu_id", "is_active"], name: "index_menu_versions_on_menu_id_and_is_active"
    t.index ["menu_id", "starts_at", "ends_at"], name: "index_menu_versions_on_menu_id_and_starts_at_and_ends_at"
    t.index ["menu_id", "version_number"], name: "index_menu_versions_on_menu_id_and_version_number", unique: true
    t.index ["menu_id"], name: "index_menu_versions_on_menu_id"
  end

  create_table "menuavailabilities", force: :cascade do |t|
    t.integer "dayofweek"
    t.integer "starthour"
    t.integer "startmin"
    t.integer "endhour"
    t.integer "endmin"
    t.bigint "menu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.integer "sequence"
    t.boolean "archived", default: false
    t.index ["menu_id", "dayofweek", "starthour"], name: "index_menuavailabilities_on_menu_day_time", where: "(archived = false)"
    t.index ["menu_id", "dayofweek"], name: "index_menuavailabilities_on_menu_and_dayofweek", unique: true
    t.index ["menu_id"], name: "index_menuavailabilities_on_menu_id"
  end

  create_table "menuitem_allergyn_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "allergyn_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allergyn_id", "menuitem_id"], name: "index_menuitem_allergyn_on_allergyn_menuitem"
    t.index ["allergyn_id"], name: "index_menuitem_allergyn_mappings_on_allergyn_id"
    t.index ["menuitem_id"], name: "index_menuitem_allergyn_mappings_on_menuitem_id"
  end

  create_table "menuitem_ingredient_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "ingredient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id", "menuitem_id"], name: "index_menuitem_ingredient_on_ingredient_menuitem"
    t.index ["ingredient_id"], name: "index_menuitem_ingredient_mappings_on_ingredient_id"
    t.index ["menuitem_id"], name: "index_menuitem_ingredient_mappings_on_menuitem_id"
  end

  create_table "menuitem_size_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "size_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "price", default: 0.0
    t.index ["menuitem_id"], name: "index_menuitem_size_mappings_on_menuitem_id"
    t.index ["size_id", "menuitem_id"], name: "index_menuitem_size_on_size_menuitem"
    t.index ["size_id"], name: "index_menuitem_size_mappings_on_size_id"
  end

  create_table "menuitem_tag_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menuitem_id"], name: "index_menuitem_tag_mappings_on_menuitem_id"
    t.index ["tag_id", "menuitem_id"], name: "index_menuitem_tag_on_tag_menuitem"
    t.index ["tag_id"], name: "index_menuitem_tag_mappings_on_tag_id"
  end

  create_table "menuitemlocales", force: :cascade do |t|
    t.string "locale"
    t.integer "status"
    t.string "name"
    t.string "description"
    t.bigint "menuitem_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menuitem_id", "locale", "status"], name: "index_menuitemlocales_on_menuitem_locale_status"
    t.index ["menuitem_id", "locale"], name: "index_menuitemlocales_on_menuitem_locale"
    t.index ["menuitem_id"], name: "index_menuitemlocales_on_menuitem_id"
  end

  create_table "menuitems", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status"
    t.integer "sequence"
    t.integer "calories"
    t.float "price"
    t.bigint "menusection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "preptime", default: 0
    t.boolean "archived", default: false
    t.text "image_data"
    t.integer "itemtype", default: 0
    t.boolean "sizesupport", default: false
    t.float "unitcost", default: 0.0
    t.boolean "tasting_optional", default: false, null: false
    t.integer "tasting_supplement_cents"
    t.string "tasting_supplement_currency"
    t.integer "course_order"
    t.boolean "hidden", default: false, null: false
    t.boolean "tasting_carrier", default: false, null: false
    t.decimal "abv", precision: 5, scale: 2
    t.string "alcohol_classification"
    t.text "alcohol_notes"
    t.string "sommelier_category"
    t.decimal "sommelier_classification_confidence", precision: 5, scale: 4
    t.jsonb "sommelier_parsed_fields", default: {}, null: false
    t.decimal "sommelier_parse_confidence", precision: 5, scale: 4
    t.boolean "sommelier_needs_review", default: false, null: false
    t.text "image_prompt"
    t.integer "ordritems_count", default: 0
    t.index "lower((name)::text) varchar_pattern_ops", name: "index_menuitems_on_lower_name"
    t.index ["alcohol_classification"], name: "index_menuitems_on_alcohol_classification"
    t.index ["archived"], name: "index_menuitems_on_archived"
    t.index ["course_order"], name: "index_menuitems_on_course_order"
    t.index ["created_at"], name: "index_menuitems_on_created_at"
    t.index ["hidden"], name: "index_menuitems_on_hidden"
    t.index ["menusection_id", "sequence"], name: "index_menuitems_on_menusection_sequence"
    t.index ["menusection_id", "status", "sequence"], name: "index_menuitems_on_section_status_sequence", where: "(archived = false)"
    t.index ["menusection_id", "status"], name: "index_menuitems_on_menusection_status"
    t.index ["menusection_id", "status"], name: "index_menuitems_on_section_status_active", where: "(archived = false)"
    t.index ["menusection_id", "tasting_carrier"], name: "index_menuitems_on_section_and_carrier"
    t.index ["menusection_id"], name: "index_menuitems_on_menusection_id"
    t.index ["sequence"], name: "index_menuitems_on_sequence"
    t.index ["sommelier_category"], name: "index_menuitems_on_sommelier_category"
    t.index ["sommelier_needs_review"], name: "index_menuitems_on_sommelier_needs_review"
    t.index ["status"], name: "index_menuitems_on_status"
    t.index ["updated_at"], name: "index_menuitems_on_updated_at"
  end

  create_table "menulocales", force: :cascade do |t|
    t.string "locale"
    t.integer "status"
    t.string "name"
    t.string "description"
    t.bigint "menu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id", "locale"], name: "index_menulocales_on_menu_locale"
    t.index ["menu_id"], name: "index_menulocales_on_menu_id"
  end

  create_table "menuparticipants", force: :cascade do |t|
    t.string "sessionid"
    t.string "preferredlocale"
    t.bigint "smartmenu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sessionid", "preferredlocale"], name: "index_menuparticipants_on_session_locale"
    t.index ["sessionid", "smartmenu_id"], name: "index_menuparticipants_on_session_smartmenu", unique: true
    t.index ["sessionid"], name: "index_menuparticipants_on_sessionid"
    t.index ["smartmenu_id"], name: "index_menuparticipants_on_smartmenu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status"
    t.integer "sequence"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "displayImages", default: false
    t.boolean "allowOrdering", default: false
    t.boolean "inventoryTracking", default: false
    t.boolean "archived", default: false
    t.text "image_data"
    t.string "imagecontext"
    t.boolean "displayImagesInPopup", default: false
    t.float "covercharge", default: 0.0
    t.bigint "menu_import_id"
    t.boolean "voiceOrderingEnabled", default: false
    t.bigint "owner_restaurant_id"
    t.integer "menuitems_count", default: 0
    t.integer "menusections_count", default: 0
    t.datetime "archived_at"
    t.string "archived_reason"
    t.bigint "archived_by_id"
    t.index ["archived"], name: "index_menus_on_archived"
    t.index ["archived_by_id"], name: "index_menus_on_archived_by_id"
    t.index ["menu_import_id"], name: "index_menus_on_menu_import_id"
    t.index ["menuitems_count"], name: "index_menus_on_menuitems_count"
    t.index ["owner_restaurant_id"], name: "index_menus_on_owner_restaurant_id"
    t.index ["restaurant_id", "created_at"], name: "index_menus_on_restaurant_created_at"
    t.index ["restaurant_id", "status"], name: "index_menus_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id", "updated_at"], name: "index_menus_on_restaurant_updated_at"
    t.index ["restaurant_id"], name: "index_menus_on_restaurant_id"
    t.index ["status"], name: "index_menus_on_status"
  end

  create_table "menusectionlocales", force: :cascade do |t|
    t.string "locale"
    t.integer "status"
    t.string "name"
    t.string "description"
    t.bigint "menusection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menusection_id", "locale"], name: "index_menusectionlocales_on_menusection_and_locale", unique: true
    t.index ["menusection_id", "status"], name: "index_menusectionlocales_on_menusection_status"
    t.index ["menusection_id"], name: "index_menusectionlocales_on_menusection_id"
  end

  create_table "menusections", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "image"
    t.integer "status"
    t.integer "sequence"
    t.bigint "menu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.text "image_data"
    t.integer "fromhour", default: 0
    t.integer "frommin", default: 0
    t.integer "tohour", default: 23
    t.integer "tomin", default: 59
    t.boolean "restricted", default: false
    t.boolean "tasting_menu", default: false, null: false
    t.integer "tasting_price_cents"
    t.string "tasting_currency"
    t.string "price_per", default: "person"
    t.integer "min_party_size"
    t.integer "max_party_size"
    t.text "includes_description"
    t.boolean "allow_substitutions", default: false, null: false
    t.boolean "allow_pairing", default: false, null: false
    t.integer "pairing_price_cents"
    t.string "pairing_currency"
    t.integer "menuitems_count", default: 0
    t.index ["menu_id", "sequence"], name: "index_menusections_on_menu_and_sequence"
    t.index ["menu_id", "status", "sequence"], name: "index_menusections_on_menu_status_sequence", where: "(archived = false)"
    t.index ["menu_id"], name: "index_menusections_on_menu_id"
    t.index ["menuitems_count"], name: "index_menusections_on_menuitems_count"
    t.index ["tasting_menu"], name: "index_menusections_on_tasting_menu"
  end

  create_table "metrics", force: :cascade do |t|
    t.integer "numberOfRestaurants"
    t.integer "numberOfMenus"
    t.integer "numberOfMenuItems"
    t.integer "numberOfOrders"
    t.float "totalOrderValue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_metrics_on_created_at"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.string "type"
    t.string "record_type"
    t.bigint "record_id"
    t.jsonb "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_count"
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.string "type"
    t.bigint "event_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "ocr_menu_imports", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.string "name", null: false
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.integer "total_pages"
    t.integer "processed_pages", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.bigint "menu_id"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_locale"
    t.integer "ai_mode", default: 0, null: false
    t.index ["menu_id"], name: "index_ocr_menu_imports_on_menu_id"
    t.index ["restaurant_id", "status", "created_at"], name: "index_ocr_imports_on_restaurant_status_created"
    t.index ["restaurant_id", "status"], name: "index_ocr_menu_imports_on_restaurant_and_status"
    t.index ["restaurant_id"], name: "index_ocr_menu_imports_on_restaurant_id"
    t.index ["source_locale"], name: "index_ocr_menu_imports_on_source_locale"
    t.index ["status"], name: "index_ocr_menu_imports_on_status"
  end

  create_table "ocr_menu_items", force: :cascade do |t|
    t.bigint "ocr_menu_section_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2
    t.text "allergens", default: [], array: true
    t.integer "sequence", default: 0, null: false
    t.boolean "is_confirmed", default: false, null: false
    t.boolean "is_vegetarian", default: false
    t.boolean "is_vegan", default: false
    t.boolean "is_gluten_free", default: false
    t.jsonb "metadata", default: {}
    t.string "page_reference"
    t.bigint "menu_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_dairy_free", default: false, null: false
    t.bigint "menuitem_id"
    t.text "image_prompt"
    t.index ["allergens"], name: "index_ocr_menu_items_on_allergens", using: :gin
    t.index ["is_confirmed"], name: "index_ocr_menu_items_on_is_confirmed"
    t.index ["is_gluten_free"], name: "index_ocr_menu_items_on_is_gluten_free"
    t.index ["is_vegan"], name: "index_ocr_menu_items_on_is_vegan"
    t.index ["is_vegetarian"], name: "index_ocr_menu_items_on_is_vegetarian"
    t.index ["menu_item_id"], name: "index_ocr_menu_items_on_menu_item_id"
    t.index ["menuitem_id"], name: "index_ocr_menu_items_on_menuitem_id"
    t.index ["ocr_menu_section_id", "is_confirmed"], name: "index_ocr_menu_items_on_section_and_confirmed"
    t.index ["ocr_menu_section_id"], name: "index_ocr_menu_items_on_ocr_menu_section_id"
    t.index ["sequence"], name: "index_ocr_menu_items_on_sequence"
  end

  create_table "ocr_menu_sections", force: :cascade do |t|
    t.bigint "ocr_menu_import_id", null: false
    t.string "name", null: false
    t.integer "sequence", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.boolean "is_confirmed", default: false, null: false
    t.string "page_reference"
    t.bigint "menu_section_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.bigint "menusection_id"
    t.index ["is_confirmed"], name: "index_ocr_menu_sections_on_is_confirmed"
    t.index ["menu_section_id"], name: "index_ocr_menu_sections_on_menu_section_id"
    t.index ["menusection_id"], name: "index_ocr_menu_sections_on_menusection_id"
    t.index ["ocr_menu_import_id", "is_confirmed"], name: "index_ocr_menu_sections_on_import_and_confirmed"
    t.index ["ocr_menu_import_id"], name: "index_ocr_menu_sections_on_ocr_menu_import_id"
    t.index ["sequence"], name: "index_ocr_menu_sections_on_sequence"
  end

  create_table "onboarding_sessions", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "status", default: 0, null: false
    t.text "wizard_data"
    t.bigint "restaurant_id"
    t.bigint "menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_onboarding_sessions_on_created_at"
    t.index ["menu_id"], name: "index_onboarding_sessions_on_menu_id"
    t.index ["restaurant_id"], name: "index_onboarding_sessions_on_restaurant_id"
    t.index ["status"], name: "index_onboarding_sessions_on_status"
    t.index ["user_id"], name: "index_onboarding_sessions_on_user_id"
  end

  create_table "order_events", force: :cascade do |t|
    t.bigint "ordr_id", null: false
    t.bigint "sequence", null: false
    t.string "event_type", null: false
    t.string "entity_type", null: false
    t.bigint "entity_id"
    t.jsonb "payload", default: {}, null: false
    t.string "source", null: false
    t.string "idempotency_key"
    t.datetime "occurred_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordr_id", "created_at", "id"], name: "index_order_events_on_ordr_id_and_created_at_and_id"
    t.index ["ordr_id", "idempotency_key"], name: "index_order_events_on_ordr_id_and_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index ["ordr_id", "sequence"], name: "index_order_events_on_ordr_id_and_sequence", unique: true
    t.index ["ordr_id"], name: "index_order_events_on_ordr_id"
  end

  create_table "ordr_split_payments", force: :cascade do |t|
    t.bigint "ordr_id", null: false
    t.bigint "ordrparticipant_id"
    t.integer "amount_cents", null: false
    t.string "currency", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordr_id"], name: "index_ordr_split_payments_on_ordr_id"
    t.index ["ordrparticipant_id"], name: "index_ordr_split_payments_on_ordrparticipant_id"
    t.index ["stripe_checkout_session_id"], name: "index_ordr_split_payments_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_ordr_split_payments_on_stripe_payment_intent_id"
  end

  create_table "ordr_station_tickets", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.bigint "ordr_id", null: false
    t.integer "station", null: false
    t.integer "status", default: 20, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sequence", default: 1, null: false
    t.datetime "submitted_at"
    t.index ["ordr_id", "station", "sequence"], name: "index_station_tickets_on_order_station_sequence", unique: true
    t.index ["ordr_id"], name: "index_ordr_station_tickets_on_ordr_id"
    t.index ["restaurant_id", "station", "status"], name: "index_station_tickets_on_restaurant_station_status"
    t.index ["restaurant_id"], name: "index_ordr_station_tickets_on_restaurant_id"
  end

  create_table "ordractions", force: :cascade do |t|
    t.integer "action"
    t.bigint "ordrparticipant_id", null: false
    t.bigint "ordr_id", null: false
    t.bigint "ordritem_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordr_id"], name: "index_ordractions_on_ordr_id"
    t.index ["ordritem_id"], name: "index_ordractions_on_ordritem_id"
    t.index ["ordrparticipant_id", "ordr_id", "action"], name: "index_ordractions_on_participant_ordr_action"
    t.index ["ordrparticipant_id"], name: "index_ordractions_on_ordrparticipant_id"
  end

  create_table "ordritemnotes", force: :cascade do |t|
    t.string "note"
    t.bigint "ordritem_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordritem_id"], name: "index_ordritemnotes_on_ordritem_id"
  end

  create_table "ordritems", force: :cascade do |t|
    t.bigint "ordr_id", null: false
    t.bigint "menuitem_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "ordritemprice", default: 0.0
    t.integer "status", default: 0
    t.bigint "ordr_station_ticket_id"
    t.string "line_key", null: false
    t.index ["created_at"], name: "index_ordritems_on_created_at"
    t.index ["menuitem_id", "status"], name: "index_ordritems_on_menuitem_status"
    t.index ["menuitem_id"], name: "index_ordritems_on_menuitem_id"
    t.index ["ordr_id", "created_at"], name: "index_ordritems_on_ordr_created_at"
    t.index ["ordr_id", "line_key"], name: "index_ordritems_on_ordr_id_and_line_key", unique: true
    t.index ["ordr_id", "status"], name: "index_ordritems_on_ordr_status"
    t.index ["ordr_id"], name: "index_ordritems_on_ordr_id"
    t.index ["ordr_station_ticket_id"], name: "index_ordritems_on_ordr_station_ticket_id"
    t.index ["status"], name: "index_ordritems_on_status"
  end

  create_table "ordrparticipant_allergyn_filters", force: :cascade do |t|
    t.bigint "ordrparticipant_id", null: false
    t.bigint "allergyn_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allergyn_id"], name: "index_ordrparticipant_allergyn_filters_on_allergyn_id"
    t.index ["ordrparticipant_id", "allergyn_id"], name: "index_ordrparticipant_allergyn_on_participant_allergyn"
    t.index ["ordrparticipant_id"], name: "index_ordrparticipant_allergyn_filters_on_ordrparticipant_id"
  end

  create_table "ordrparticipants", force: :cascade do |t|
    t.string "sessionid"
    t.integer "role"
    t.bigint "ordr_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "ordritem_id"
    t.bigint "employee_id"
    t.string "preferredlocale"
    t.index ["employee_id"], name: "index_ordrparticipants_on_employee_id"
    t.index ["ordr_id", "role", "employee_id"], name: "index_ordrparticipants_on_ordr_role_employee"
    t.index ["ordr_id", "role", "sessionid"], name: "index_ordrparticipants_on_ordr_role_session"
    t.index ["ordr_id"], name: "index_ordrparticipants_on_ordr_id"
    t.index ["ordritem_id"], name: "index_ordrparticipants_on_ordritem_id"
    t.index ["sessionid", "preferredlocale"], name: "index_ordrparticipants_on_session_locale"
  end

  create_table "ordrs", id: :serial, force: :cascade do |t|
    t.datetime "orderedAt", precision: nil
    t.datetime "deliveredAt", precision: nil
    t.datetime "paidAt", precision: nil
    t.float "nett"
    t.float "tip"
    t.float "service"
    t.float "tax"
    t.float "gross"
    t.integer "employee_id"
    t.bigint "tablesetting_id", null: false
    t.bigint "menu_id", null: false
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status"
    t.datetime "billRequestedAt"
    t.integer "ordercapacity", default: 0
    t.float "covercharge", default: 0.0
    t.string "paymentlink"
    t.integer "paymentstatus", default: 0
    t.bigint "last_projected_order_event_sequence", default: 0, null: false
    t.integer "ordritems_count", default: 0
    t.integer "ordrparticipants_count", default: 0
    t.index ["created_at"], name: "index_ordrs_on_created_at"
    t.index ["employee_id", "created_at"], name: "index_ordrs_on_employee_created_at"
    t.index ["employee_id"], name: "index_ordrs_on_employee_id"
    t.index ["last_projected_order_event_sequence"], name: "index_ordrs_on_last_projected_order_event_sequence"
    t.index ["menu_id", "tablesetting_id", "status"], name: "index_ordrs_on_menu_table_status"
    t.index ["menu_id"], name: "index_ordrs_on_menu_id"
    t.index ["ordritems_count"], name: "index_ordrs_on_ordritems_count"
    t.index ["restaurant_id", "created_at", "gross"], name: "index_ordrs_on_restaurant_created_gross"
    t.index ["restaurant_id", "created_at", "status"], name: "index_ordrs_on_restaurant_created_status"
    t.index ["restaurant_id", "status", "created_at"], name: "index_ordrs_on_restaurant_status_created"
    t.index ["restaurant_id", "status"], name: "index_ordrs_on_restaurant_status"
    t.index ["restaurant_id"], name: "index_ordrs_on_restaurant_id"
    t.index ["status"], name: "index_ordrs_on_status"
    t.index ["tablesetting_id", "status", "created_at"], name: "index_ordrs_on_table_status_created"
    t.index ["tablesetting_id", "status"], name: "index_ordrs_on_tablesetting_and_status"
    t.index ["tablesetting_id"], name: "index_ordrs_on_tablesetting_id"
    t.index ["updated_at"], name: "index_ordrs_on_updated_at"
  end

  create_table "pairing_recommendations", force: :cascade do |t|
    t.bigint "drink_menuitem_id", null: false
    t.bigint "food_menuitem_id", null: false
    t.decimal "complement_score", precision: 5, scale: 4, default: "0.0"
    t.decimal "contrast_score", precision: 5, scale: 4, default: "0.0"
    t.decimal "score", precision: 5, scale: 4, default: "0.0"
    t.text "rationale"
    t.jsonb "risk_flags", default: [], null: false
    t.string "pairing_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drink_menuitem_id", "food_menuitem_id"], name: "idx_pairings_drink_food", unique: true
    t.index ["drink_menuitem_id"], name: "index_pairing_recommendations_on_drink_menuitem_id"
    t.index ["food_menuitem_id"], name: "index_pairing_recommendations_on_food_menuitem_id"
  end

  create_table "pay_charges", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "subscription_id"
    t.string "processor_id", null: false
    t.integer "amount", null: false
    t.string "currency"
    t.integer "application_fee_amount"
    t.integer "amount_refunded"
    t.jsonb "metadata"
    t.jsonb "data"
    t.string "stripe_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.jsonb "data"
    t.string "stripe_account"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
    t.index ["processor_id"], name: "index_pay_merchants_on_processor_id"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "processor_id", null: false
    t.boolean "default"
    t.string "payment_method_type"
    t.jsonb "data"
    t.string "stripe_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name", null: false
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.datetime "current_period_start", precision: nil
    t.datetime "current_period_end", precision: nil
    t.datetime "trial_ends_at", precision: nil
    t.datetime "ends_at", precision: nil
    t.boolean "metered"
    t.string "pause_behavior"
    t.datetime "pause_starts_at", precision: nil
    t.datetime "pause_resumes_at", precision: nil
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.jsonb "metadata"
    t.jsonb "data"
    t.string "stripe_account"
    t.string "payment_method_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
    t.index ["payment_method_id"], name: "index_pay_subscriptions_on_payment_method_id"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.string "processor"
    t.string "event_type"
    t.jsonb "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_attempts", force: :cascade do |t|
    t.bigint "ordr_id", null: false
    t.bigint "restaurant_id", null: false
    t.integer "provider", default: 0, null: false
    t.string "provider_payment_id"
    t.integer "amount_cents", null: false
    t.string "currency", null: false
    t.integer "status", default: 0, null: false
    t.integer "charge_pattern", default: 0, null: false
    t.integer "merchant_model", default: 0, null: false
    t.integer "platform_fee_cents"
    t.integer "provider_fee_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordr_id", "created_at"], name: "index_payment_attempts_on_ordr_id_and_created_at"
    t.index ["ordr_id"], name: "index_payment_attempts_on_ordr_id"
    t.index ["provider", "provider_payment_id"], name: "index_payment_attempts_on_provider_and_provider_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"
    t.index ["restaurant_id", "created_at"], name: "index_payment_attempts_on_restaurant_id_and_created_at"
    t.index ["restaurant_id"], name: "index_payment_attempts_on_restaurant_id"
  end

  create_table "payment_profiles", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.integer "merchant_model", default: 0, null: false
    t.integer "primary_provider", default: 0, null: false
    t.jsonb "fallback_providers", default: {}, null: false
    t.string "default_country"
    t.string "default_currency"
    t.jsonb "fee_model", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_payment_profiles_on_restaurant_id", unique: true
  end

  create_table "payment_refunds", force: :cascade do |t|
    t.bigint "payment_attempt_id", null: false
    t.bigint "ordr_id", null: false
    t.bigint "restaurant_id", null: false
    t.integer "provider", default: 0, null: false
    t.string "provider_refund_id"
    t.integer "amount_cents"
    t.string "currency"
    t.integer "status", default: 0, null: false
    t.jsonb "provider_response_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordr_id"], name: "index_payment_refunds_on_ordr_id"
    t.index ["payment_attempt_id", "created_at"], name: "index_payment_refunds_on_payment_attempt_id_and_created_at"
    t.index ["payment_attempt_id"], name: "index_payment_refunds_on_payment_attempt_id"
    t.index ["provider", "provider_refund_id"], name: "index_payment_refunds_on_provider_and_provider_refund_id", unique: true, where: "(provider_refund_id IS NOT NULL)"
    t.index ["restaurant_id"], name: "index_payment_refunds_on_restaurant_id"
  end

  create_table "performance_metrics", force: :cascade do |t|
    t.string "endpoint", null: false
    t.float "response_time", null: false
    t.integer "memory_usage"
    t.integer "status_code", null: false
    t.bigint "user_id"
    t.string "controller"
    t.string "action"
    t.datetime "timestamp", null: false
    t.json "additional_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint", "timestamp"], name: "index_performance_metrics_on_endpoint_and_timestamp"
    t.index ["response_time"], name: "index_performance_metrics_on_response_time"
    t.index ["status_code", "timestamp"], name: "index_performance_metrics_on_status_code_and_timestamp"
    t.index ["timestamp"], name: "index_performance_metrics_on_timestamp"
    t.index ["user_id"], name: "index_performance_metrics_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "key"
    t.string "descriptionKey"
    t.string "attribute1"
    t.string "attribute2"
    t.string "attribute3"
    t.string "attribute4"
    t.string "attribute5"
    t.string "attribut6"
    t.integer "status"
    t.boolean "favourite"
    t.decimal "pricePerMonth"
    t.decimal "pricePerYear"
    t.integer "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "itemspermenu", default: 0
    t.integer "languages", default: 0
    t.integer "locations", default: 0
    t.integer "menusperlocation", default: 0
    t.string "stripe_price_id_month"
    t.string "stripe_price_id_year"
    t.index ["stripe_price_id_month"], name: "index_plans_on_stripe_price_id_month"
    t.index ["stripe_price_id_year"], name: "index_plans_on_stripe_price_id_year"
  end

  create_table "product_enrichments", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "source", null: false
    t.string "external_id"
    t.jsonb "payload_json", default: {}, null: false
    t.datetime "fetched_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "source"], name: "index_product_enrichments_on_product_id_and_source"
    t.index ["product_id"], name: "index_product_enrichments_on_product_id"
    t.index ["source", "external_id"], name: "index_product_enrichments_on_source_and_external_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "product_type", null: false
    t.string "canonical_name", null: false
    t.jsonb "attributes_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_type", "canonical_name"], name: "index_products_on_product_type_and_canonical_name", unique: true
  end

  create_table "provider_accounts", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.integer "provider", default: 0, null: false
    t.string "provider_account_id", null: false
    t.string "account_type"
    t.string "country"
    t.string "currency"
    t.integer "status", default: 0, null: false
    t.jsonb "capabilities", default: {}, null: false
    t.boolean "payouts_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_account_id"], name: "index_provider_accounts_on_provider_and_provider_account_id", unique: true
    t.index ["restaurant_id", "provider"], name: "index_provider_accounts_on_restaurant_id_and_provider"
    t.index ["restaurant_id"], name: "index_provider_accounts_on_restaurant_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false
    t.text "p256dh_key", null: false
    t.text "auth_key", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id", "active"], name: "index_push_subscriptions_on_user_id_and_active"
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "resource_locks", force: :cascade do |t|
    t.string "resource_type", null: false
    t.bigint "resource_id", null: false
    t.string "field_name"
    t.bigint "user_id", null: false
    t.string "session_id", null: false
    t.datetime "acquired_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_resource_locks_on_expires_at"
    t.index ["resource_type", "resource_id", "field_name"], name: "index_resource_locks_on_resource_and_field", unique: true
    t.index ["session_id"], name: "index_resource_locks_on_session_id"
    t.index ["user_id"], name: "index_resource_locks_on_user_id"
  end

  create_table "restaurant_claim_requests", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.bigint "initiated_by_user_id"
    t.integer "status", default: 0, null: false
    t.integer "verification_method", default: 0, null: false
    t.string "claimant_email", null: false
    t.string "claimant_name"
    t.text "evidence"
    t.text "review_notes"
    t.datetime "verified_at"
    t.bigint "reviewed_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["initiated_by_user_id"], name: "index_restaurant_claim_requests_on_initiated_by_user_id"
    t.index ["restaurant_id", "status"], name: "index_restaurant_claim_requests_on_restaurant_id_and_status"
    t.index ["restaurant_id"], name: "index_restaurant_claim_requests_on_restaurant_id"
    t.index ["reviewed_by_user_id"], name: "index_restaurant_claim_requests_on_reviewed_by_user_id"
  end

  create_table "restaurant_menus", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.bigint "menu_id", null: false
    t.integer "sequence"
    t.integer "status", default: 1, null: false
    t.boolean "availability_override_enabled", default: false, null: false
    t.integer "availability_state", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at"
    t.string "archived_reason"
    t.bigint "archived_by_id"
    t.index ["archived_by_id"], name: "index_restaurant_menus_on_archived_by_id"
    t.index ["menu_id"], name: "index_restaurant_menus_on_menu_id"
    t.index ["restaurant_id", "menu_id"], name: "index_restaurant_menus_on_restaurant_id_and_menu_id", unique: true
    t.index ["restaurant_id"], name: "index_restaurant_menus_on_restaurant_id"
  end

  create_table "restaurant_onboardings", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.integer "status", default: 0
    t.jsonb "progress_steps", default: {}
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_restaurant_onboardings_on_restaurant_id"
  end

  create_table "restaurant_removal_requests", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.string "requested_by_email", null: false
    t.integer "source", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.text "admin_notes"
    t.datetime "actioned_at"
    t.bigint "actioned_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actioned_by_user_id"], name: "index_restaurant_removal_requests_on_actioned_by_user_id"
    t.index ["restaurant_id", "status"], name: "index_restaurant_removal_requests_on_restaurant_id_and_status"
    t.index ["restaurant_id"], name: "index_restaurant_removal_requests_on_restaurant_id"
  end

  create_table "restaurant_subscriptions", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.boolean "payment_method_on_file", default: false, null: false
    t.datetime "trial_ends_at"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_restaurant_subscriptions_on_restaurant_id", unique: true
    t.index ["stripe_customer_id"], name: "index_restaurant_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_restaurant_subscriptions_on_stripe_subscription_id"
  end

  create_table "restaurantavailabilities", force: :cascade do |t|
    t.integer "dayofweek"
    t.integer "starthour"
    t.integer "startmin"
    t.integer "endhour"
    t.integer "endmin"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.integer "sequence"
    t.boolean "archived", default: false
    t.index ["restaurant_id"], name: "index_restaurantavailabilities_on_restaurant_id"
  end

  create_table "restaurantlocales", force: :cascade do |t|
    t.string "locale"
    t.integer "status"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "dfault"
    t.integer "sequence", default: 0, null: false
    t.index ["restaurant_id", "locale"], name: "index_restaurantlocales_on_restaurant_locale"
    t.index ["restaurant_id", "sequence"], name: "index_restaurantlocales_on_restaurant_id_and_sequence"
    t.index ["restaurant_id", "status", "dfault"], name: "index_restaurantlocales_on_restaurant_status_default"
    t.index ["restaurant_id"], name: "index_restaurantlocales_on_restaurant_id"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "address1"
    t.string "address2"
    t.string "state"
    t.string "city"
    t.string "postcode"
    t.string "country"
    t.integer "status"
    t.integer "capacity"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "genid"
    t.boolean "displayImages", default: false
    t.boolean "allowOrdering", default: false
    t.boolean "inventoryTracking", default: false
    t.string "currency"
    t.boolean "archived", default: false
    t.float "latitude"
    t.float "longitude"
    t.integer "sequence"
    t.text "image_data"
    t.string "imagecontext"
    t.string "wifissid"
    t.integer "wifiEncryptionType", default: 0
    t.string "wifiPassword"
    t.boolean "wifiHidden", default: false
    t.string "spotifyuserid"
    t.string "spotifyaccesstoken"
    t.string "spotifyrefreshtoken"
    t.boolean "displayImagesInPopup", default: false
    t.text "image_style_profile"
    t.boolean "allow_alcohol", default: false, null: false
    t.string "timezone", default: "UTC"
    t.integer "menus_count", default: 0
    t.integer "employees_count", default: 0
    t.integer "ordrs_count", default: 0
    t.integer "tablesettings_count", default: 0
    t.integer "ocr_menu_imports_count", default: 0
    t.datetime "archived_at"
    t.string "archived_reason"
    t.bigint "archived_by_id"
    t.string "google_place_id"
    t.integer "claim_status", default: 0, null: false
    t.boolean "preview_enabled", default: false, null: false
    t.datetime "preview_published_at"
    t.boolean "preview_indexable", default: false, null: false
    t.string "establishment_types", default: [], null: false, array: true
    t.integer "provisioned_by", default: 0
    t.string "source_url"
    t.boolean "ordering_enabled", default: false, null: false
    t.boolean "payments_enabled", default: false, null: false
    t.boolean "whiskey_ambassador_enabled", default: false, null: false
    t.integer "max_whiskey_flights", default: 5, null: false
    t.index ["archived_by_id"], name: "index_restaurants_on_archived_by_id"
    t.index ["city", "country", "preview_enabled"], name: "idx_restaurants_geo_preview"
    t.index ["claim_status"], name: "index_restaurants_on_claim_status"
    t.index ["employees_count"], name: "index_restaurants_on_employees_count"
    t.index ["google_place_id"], name: "index_restaurants_on_google_place_id", unique: true
    t.index ["menus_count"], name: "index_restaurants_on_menus_count"
    t.index ["preview_enabled", "claim_status"], name: "idx_restaurants_preview_claim"
    t.index ["preview_published_at"], name: "index_restaurants_on_preview_published_at"
    t.index ["user_id", "status"], name: "index_restaurants_on_user_status_active", where: "(archived = false)"
    t.index ["user_id"], name: "index_restaurants_on_user_id"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider"
    t.string "uid"
    t.string "access_token"
    t.string "access_token_secret"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.text "auth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_services_on_user_id"
  end

  create_table "similar_product_recommendations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "recommended_product_id", null: false
    t.decimal "score", precision: 5, scale: 4, default: "0.0"
    t.text "rationale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "recommended_product_id"], name: "idx_similar_products_pair", unique: true
    t.index ["product_id"], name: "index_similar_product_recommendations_on_product_id"
    t.index ["recommended_product_id"], name: "idx_on_recommended_product_id_d9294a2c90"
  end

  create_table "sizes", force: :cascade do |t|
    t.integer "size"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "status", default: 0
    t.integer "sequence"
    t.bigint "restaurant_id"
    t.index ["restaurant_id", "status"], name: "index_sizes_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id"], name: "index_sizes_on_restaurant_id"
  end

  create_table "slow_queries", force: :cascade do |t|
    t.text "sql", null: false
    t.float "duration", null: false
    t.string "query_name"
    t.text "backtrace"
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duration", "timestamp"], name: "index_slow_queries_on_duration_and_timestamp"
    t.index ["timestamp"], name: "index_slow_queries_on_timestamp"
  end

  create_table "smartmenus", force: :cascade do |t|
    t.string "slug", null: false
    t.bigint "restaurant_id", null: false
    t.bigint "menu_id"
    t.bigint "tablesetting_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_smartmenus_on_menu_id"
    t.index ["restaurant_id", "menu_id", "tablesetting_id"], name: "uniq_smartmenus_restaurant_menu_table", unique: true, where: "((menu_id IS NOT NULL) AND (tablesetting_id IS NOT NULL))"
    t.index ["restaurant_id", "menu_id"], name: "uniq_smartmenus_restaurant_menu_global", unique: true, where: "((tablesetting_id IS NULL) AND (menu_id IS NOT NULL))"
    t.index ["restaurant_id", "slug"], name: "index_smartmenus_on_restaurant_slug"
    t.index ["restaurant_id", "tablesetting_id"], name: "uniq_smartmenus_restaurant_table_general", unique: true, where: "((menu_id IS NULL) AND (tablesetting_id IS NOT NULL))"
    t.index ["restaurant_id"], name: "index_smartmenus_on_restaurant_id"
    t.index ["slug"], name: "index_smartmenus_on_slug"
    t.index ["tablesetting_id"], name: "index_smartmenus_on_tablesetting_id"
  end

  create_table "tablesettings", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status"
    t.integer "capacity"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tabletype"
    t.boolean "archived", default: false
    t.integer "sequence"
    t.index ["restaurant_id", "created_at"], name: "index_tablesettings_on_restaurant_created_at"
    t.index ["restaurant_id", "status"], name: "index_tablesettings_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id"], name: "index_tablesettings_on_restaurant_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "typs"
    t.boolean "archived", default: false
  end

  create_table "taxes", force: :cascade do |t|
    t.string "name"
    t.integer "taxtype"
    t.float "taxpercentage"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sequence"
    t.boolean "archived", default: false
    t.integer "status", default: 0
    t.index ["restaurant_id", "status"], name: "index_taxes_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id"], name: "index_taxes_on_restaurant_id"
  end

  create_table "testimonials", force: :cascade do |t|
    t.integer "sequence"
    t.integer "status"
    t.string "testimonial"
    t.bigint "user_id", null: false
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_testimonials_on_restaurant_id"
    t.index ["user_id"], name: "index_testimonials_on_user_id"
  end

  create_table "tips", force: :cascade do |t|
    t.float "percentage"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "sequence"
    t.integer "status", default: 0
    t.index ["restaurant_id", "status"], name: "index_tips_on_restaurant_status_active", where: "(archived = false)"
    t.index ["restaurant_id"], name: "index_tips_on_restaurant_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.string "externalid"
    t.string "name"
    t.text "description"
    t.string "image"
    t.integer "sequence"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "artist"
    t.boolean "explicit"
    t.boolean "is_playable"
    t.integer "status"
    t.index ["restaurant_id"], name: "index_tracks_on_restaurant_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "session_id", null: false
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "status", default: "active", null: false
    t.datetime "last_activity_at"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_activity_at"], name: "index_user_sessions_on_last_activity_at"
    t.index ["resource_type", "resource_id"], name: "index_user_sessions_on_resource_type_and_resource_id"
    t.index ["session_id"], name: "index_user_sessions_on_session_id", unique: true
    t.index ["user_id", "status"], name: "index_user_sessions_on_user_id_and_status"
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "userplans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_userplans_on_plan_id"
    t.index ["user_id"], name: "index_userplans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "announcements_last_read_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "plan_id"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "restaurants_count", default: 0
    t.integer "employees_count", default: 0
    t.boolean "super_admin", default: false, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["admin", "super_admin"], name: "index_users_on_admin_and_super_admin"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plan_id", "admin"], name: "index_users_on_plan_admin"
    t.index ["plan_id"], name: "index_users_on_plan_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "voice_commands", force: :cascade do |t|
    t.bigint "smartmenu_id", null: false
    t.string "session_id", null: false
    t.string "status", default: "queued", null: false
    t.string "locale"
    t.text "transcript"
    t.jsonb "intent"
    t.jsonb "result"
    t.text "error_message"
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["smartmenu_id", "session_id", "created_at"], name: "idx_on_smartmenu_id_session_id_created_at_dc50bab09c"
    t.index ["smartmenu_id"], name: "index_voice_commands_on_smartmenu_id"
    t.index ["status"], name: "index_voice_commands_on_status"
  end

  create_table "whiskey_flights", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.string "theme_key", null: false
    t.string "title", null: false
    t.text "narrative"
    t.jsonb "items", default: [], null: false
    t.string "source", default: "ai", null: false
    t.string "status", default: "draft", null: false
    t.float "total_price"
    t.float "custom_price"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id", "theme_key"], name: "index_whiskey_flights_on_menu_id_and_theme_key", unique: true
    t.index ["menu_id"], name: "index_whiskey_flights_on_menu_id"
    t.index ["status"], name: "index_whiskey_flights_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alcohol_order_events", "menuitems"
  add_foreign_key "alcohol_order_events", "ordritems"
  add_foreign_key "alcohol_order_events", "ordrs"
  add_foreign_key "alcohol_order_events", "restaurants"
  add_foreign_key "alcohol_policies", "restaurants"
  add_foreign_key "allergyns", "restaurants"
  add_foreign_key "beverage_pipeline_runs", "menus"
  add_foreign_key "beverage_pipeline_runs", "restaurants"
  add_foreign_key "crawl_source_rules", "users", column: "created_by_user_id"
  add_foreign_key "discovered_restaurants", "restaurants"
  add_foreign_key "employees", "restaurants"
  add_foreign_key "employees", "users"
  add_foreign_key "features_plans", "features"
  add_foreign_key "features_plans", "plans"
  add_foreign_key "genimages", "menuitems"
  add_foreign_key "genimages", "menus"
  add_foreign_key "genimages", "menusections"
  add_foreign_key "genimages", "restaurants"
  add_foreign_key "impersonation_audits", "users", column: "admin_user_id"
  add_foreign_key "impersonation_audits", "users", column: "impersonated_user_id"
  add_foreign_key "inventories", "menuitems"
  add_foreign_key "menu_edit_sessions", "menus"
  add_foreign_key "menu_edit_sessions", "users"
  add_foreign_key "menu_imports", "restaurants"
  add_foreign_key "menu_imports", "users"
  add_foreign_key "menu_item_product_links", "menuitems"
  add_foreign_key "menu_item_product_links", "products"
  add_foreign_key "menu_items", "menu_sections"
  add_foreign_key "menu_sections", "menus"
  add_foreign_key "menu_source_change_reviews", "menu_sources"
  add_foreign_key "menu_sources", "discovered_restaurants"
  add_foreign_key "menu_sources", "restaurants"
  add_foreign_key "menu_versions", "menus"
  add_foreign_key "menu_versions", "users", column: "created_by_user_id"
  add_foreign_key "menuavailabilities", "menus"
  add_foreign_key "menuitem_allergyn_mappings", "allergyns"
  add_foreign_key "menuitem_allergyn_mappings", "menuitems"
  add_foreign_key "menuitem_ingredient_mappings", "ingredients"
  add_foreign_key "menuitem_ingredient_mappings", "menuitems"
  add_foreign_key "menuitem_size_mappings", "menuitems"
  add_foreign_key "menuitem_size_mappings", "sizes"
  add_foreign_key "menuitem_tag_mappings", "menuitems"
  add_foreign_key "menuitem_tag_mappings", "tags"
  add_foreign_key "menuitemlocales", "menuitems"
  add_foreign_key "menuitems", "menusections"
  add_foreign_key "menulocales", "menus"
  add_foreign_key "menuparticipants", "smartmenus"
  add_foreign_key "menus", "menu_imports"
  add_foreign_key "menus", "restaurants"
  add_foreign_key "menus", "restaurants", column: "owner_restaurant_id"
  add_foreign_key "menus", "users", column: "archived_by_id"
  add_foreign_key "menusectionlocales", "menusections"
  add_foreign_key "menusections", "menus"
  add_foreign_key "ocr_menu_imports", "menus"
  add_foreign_key "ocr_menu_imports", "restaurants"
  add_foreign_key "ocr_menu_items", "menu_items"
  add_foreign_key "ocr_menu_items", "menuitems"
  add_foreign_key "ocr_menu_items", "ocr_menu_sections"
  add_foreign_key "ocr_menu_sections", "menu_sections"
  add_foreign_key "ocr_menu_sections", "menusections"
  add_foreign_key "ocr_menu_sections", "ocr_menu_imports"
  add_foreign_key "onboarding_sessions", "menus"
  add_foreign_key "onboarding_sessions", "restaurants"
  add_foreign_key "onboarding_sessions", "users"
  add_foreign_key "order_events", "ordrs"
  add_foreign_key "ordr_split_payments", "ordrparticipants"
  add_foreign_key "ordr_split_payments", "ordrs"
  add_foreign_key "ordr_station_tickets", "ordrs"
  add_foreign_key "ordr_station_tickets", "restaurants"
  add_foreign_key "ordractions", "ordritems"
  add_foreign_key "ordractions", "ordrparticipants"
  add_foreign_key "ordritemnotes", "ordritems"
  add_foreign_key "ordritems", "menuitems"
  add_foreign_key "ordritems", "ordr_station_tickets"
  add_foreign_key "ordrparticipant_allergyn_filters", "allergyns"
  add_foreign_key "ordrparticipant_allergyn_filters", "ordrparticipants"
  add_foreign_key "ordrparticipants", "employees"
  add_foreign_key "ordrparticipants", "ordritems"
  add_foreign_key "ordrs", "employees"
  add_foreign_key "ordrs", "menus"
  add_foreign_key "ordrs", "restaurants"
  add_foreign_key "ordrs", "tablesettings"
  add_foreign_key "pairing_recommendations", "menuitems", column: "drink_menuitem_id"
  add_foreign_key "pairing_recommendations", "menuitems", column: "food_menuitem_id"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "payment_attempts", "ordrs"
  add_foreign_key "payment_attempts", "restaurants"
  add_foreign_key "payment_profiles", "restaurants"
  add_foreign_key "payment_refunds", "ordrs"
  add_foreign_key "payment_refunds", "payment_attempts"
  add_foreign_key "payment_refunds", "restaurants"
  add_foreign_key "performance_metrics", "users"
  add_foreign_key "product_enrichments", "products"
  add_foreign_key "provider_accounts", "restaurants"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "resource_locks", "users"
  add_foreign_key "restaurant_claim_requests", "restaurants"
  add_foreign_key "restaurant_claim_requests", "users", column: "initiated_by_user_id"
  add_foreign_key "restaurant_claim_requests", "users", column: "reviewed_by_user_id"
  add_foreign_key "restaurant_menus", "menus"
  add_foreign_key "restaurant_menus", "restaurants"
  add_foreign_key "restaurant_menus", "users", column: "archived_by_id"
  add_foreign_key "restaurant_onboardings", "restaurants"
  add_foreign_key "restaurant_removal_requests", "restaurants"
  add_foreign_key "restaurant_removal_requests", "users", column: "actioned_by_user_id"
  add_foreign_key "restaurant_subscriptions", "restaurants"
  add_foreign_key "restaurantavailabilities", "restaurants"
  add_foreign_key "restaurantlocales", "restaurants"
  add_foreign_key "restaurants", "users"
  add_foreign_key "restaurants", "users", column: "archived_by_id"
  add_foreign_key "services", "users"
  add_foreign_key "similar_product_recommendations", "products"
  add_foreign_key "similar_product_recommendations", "products", column: "recommended_product_id"
  add_foreign_key "sizes", "restaurants"
  add_foreign_key "smartmenus", "menus"
  add_foreign_key "smartmenus", "restaurants"
  add_foreign_key "smartmenus", "tablesettings"
  add_foreign_key "tablesettings", "restaurants"
  add_foreign_key "taxes", "restaurants"
  add_foreign_key "testimonials", "restaurants"
  add_foreign_key "testimonials", "users"
  add_foreign_key "tips", "restaurants"
  add_foreign_key "tracks", "restaurants"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "userplans", "plans"
  add_foreign_key "userplans", "users"
  add_foreign_key "voice_commands", "smartmenus"
  add_foreign_key "whiskey_flights", "menus"
end

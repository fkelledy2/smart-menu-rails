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

ActiveRecord::Schema[7.1].define(version: 2025_05_22_190416) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "contacts", force: :cascade do |t|
    t.string "email"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["restaurant_id"], name: "index_employees_on_restaurant_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
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
    t.index ["menu_id"], name: "index_genimages_on_menu_id"
    t.index ["menuitem_id"], name: "index_genimages_on_menuitem_id"
    t.index ["menusection_id"], name: "index_genimages_on_menusection_id"
    t.index ["restaurant_id"], name: "index_genimages_on_restaurant_id"
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
    t.index ["menuitem_id"], name: "index_inventories_on_menuitem_id"
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
    t.index ["menu_id"], name: "index_menuavailabilities_on_menu_id"
  end

  create_table "menuitem_allergyn_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "allergyn_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allergyn_id"], name: "index_menuitem_allergyn_mappings_on_allergyn_id"
    t.index ["menuitem_id"], name: "index_menuitem_allergyn_mappings_on_menuitem_id"
  end

  create_table "menuitem_ingredient_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "ingredient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["size_id"], name: "index_menuitem_size_mappings_on_size_id"
  end

  create_table "menuitem_tag_mappings", force: :cascade do |t|
    t.bigint "menuitem_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menuitem_id"], name: "index_menuitem_tag_mappings_on_menuitem_id"
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
    t.index ["menusection_id"], name: "index_menuitems_on_menusection_id"
  end

  create_table "menulocales", force: :cascade do |t|
    t.string "locale"
    t.integer "status"
    t.string "name"
    t.string "description"
    t.bigint "menu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_menulocales_on_menu_id"
  end

  create_table "menuparticipants", force: :cascade do |t|
    t.string "sessionid"
    t.string "preferredlocale"
    t.bigint "smartmenu_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["restaurant_id"], name: "index_menus_on_restaurant_id"
  end

  create_table "menusectionlocales", force: :cascade do |t|
    t.string "locale"
    t.integer "status"
    t.string "name"
    t.string "description"
    t.bigint "menusection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["menu_id"], name: "index_menusections_on_menu_id"
  end

  create_table "metrics", force: :cascade do |t|
    t.integer "numberOfRestaurants"
    t.integer "numberOfMenus"
    t.integer "numberOfMenuItems"
    t.integer "numberOfOrders"
    t.float "totalOrderValue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "ordractions", force: :cascade do |t|
    t.integer "action"
    t.bigint "ordrparticipant_id", null: false
    t.bigint "ordr_id", null: false
    t.bigint "ordritem_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordr_id"], name: "index_ordractions_on_ordr_id"
    t.index ["ordritem_id"], name: "index_ordractions_on_ordritem_id"
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
    t.index ["menuitem_id"], name: "index_ordritems_on_menuitem_id"
    t.index ["ordr_id"], name: "index_ordritems_on_ordr_id"
  end

  create_table "ordrparticipant_allergyn_filters", force: :cascade do |t|
    t.bigint "ordrparticipant_id", null: false
    t.bigint "allergyn_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allergyn_id"], name: "index_ordrparticipant_allergyn_filters_on_allergyn_id"
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
    t.index ["ordr_id"], name: "index_ordrparticipants_on_ordr_id"
    t.index ["ordritem_id"], name: "index_ordrparticipants_on_ordritem_id"
  end

  create_table "ordrs", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.datetime "billRequestedAt"
    t.index ["employee_id"], name: "index_ordrs_on_employee_id"
    t.index ["menu_id"], name: "index_ordrs_on_menu_id"
    t.index ["restaurant_id"], name: "index_ordrs_on_restaurant_id"
    t.index ["tablesetting_id"], name: "index_ordrs_on_tablesetting_id"
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
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.string "processor"
    t.string "event_type"
    t.jsonb "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["restaurant_id"], name: "index_sizes_on_restaurant_id"
  end

  create_table "smartmenus", force: :cascade do |t|
    t.string "slug", null: false
    t.bigint "restaurant_id", null: false
    t.bigint "menu_id"
    t.bigint "tablesetting_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_smartmenus_on_menu_id"
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
    t.index ["restaurant_id"], name: "index_taxes_on_restaurant_id"
  end

  create_table "tips", force: :cascade do |t|
    t.float "percentage"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "sequence"
    t.integer "status", default: 0
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
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "plan_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plan_id"], name: "index_users_on_plan_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "allergyns", "restaurants"
  add_foreign_key "employees", "restaurants"
  add_foreign_key "employees", "users"
  add_foreign_key "features_plans", "features"
  add_foreign_key "features_plans", "plans"
  add_foreign_key "genimages", "menuitems"
  add_foreign_key "genimages", "menus"
  add_foreign_key "genimages", "menusections"
  add_foreign_key "genimages", "restaurants"
  add_foreign_key "inventories", "menuitems"
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
  add_foreign_key "menus", "restaurants"
  add_foreign_key "menusectionlocales", "menusections"
  add_foreign_key "menusections", "menus"
  add_foreign_key "ordractions", "ordritems"
  add_foreign_key "ordractions", "ordrparticipants"
  add_foreign_key "ordractions", "ordrs"
  add_foreign_key "ordritemnotes", "ordritems"
  add_foreign_key "ordritems", "menuitems"
  add_foreign_key "ordritems", "ordrs"
  add_foreign_key "ordrparticipant_allergyn_filters", "allergyns"
  add_foreign_key "ordrparticipant_allergyn_filters", "ordrparticipants"
  add_foreign_key "ordrparticipants", "employees"
  add_foreign_key "ordrparticipants", "ordritems"
  add_foreign_key "ordrparticipants", "ordrs"
  add_foreign_key "ordrs", "employees"
  add_foreign_key "ordrs", "menus"
  add_foreign_key "ordrs", "restaurants"
  add_foreign_key "ordrs", "tablesettings"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "restaurantavailabilities", "restaurants"
  add_foreign_key "restaurantlocales", "restaurants"
  add_foreign_key "restaurants", "users"
  add_foreign_key "services", "users"
  add_foreign_key "sizes", "restaurants"
  add_foreign_key "smartmenus", "menus"
  add_foreign_key "smartmenus", "restaurants"
  add_foreign_key "smartmenus", "tablesettings"
  add_foreign_key "tablesettings", "restaurants"
  add_foreign_key "taxes", "restaurants"
  add_foreign_key "tips", "restaurants"
  add_foreign_key "tracks", "restaurants"
  add_foreign_key "userplans", "plans"
  add_foreign_key "userplans", "users"
end

class InitSchema < ActiveRecord::Migration[5.0]
  def up
    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"
    create_table "active_storage_attachments" do |t|
      t.string "name", null: false
      t.string "record_type", null: false
      t.bigint "record_id", null: false
      t.bigint "blob_id", null: false
      t.datetime "created_at", null: false
      t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
      t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    end
    create_table "active_storage_blobs" do |t|
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
    create_table "active_storage_variant_records" do |t|
      t.bigint "blob_id", null: false
      t.string "variation_digest", null: false
      t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
    end
    create_table "allergyns" do |t|
      t.string "name"
      t.text "description"
      t.string "symbol"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    create_table "announcements" do |t|
      t.datetime "published_at"
      t.string "announcement_type"
      t.string "name"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    create_table "employees" do |t|
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
      t.index ["restaurant_id"], name: "index_employees_on_restaurant_id"
      t.index ["user_id"], name: "index_employees_on_user_id"
    end
    create_table "friendly_id_slugs" do |t|
      t.string "slug", null: false
      t.integer "sluggable_id", null: false
      t.string "sluggable_type", limit: 50
      t.string "scope"
      t.datetime "created_at"
      t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
      t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
      t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
    end
    create_table "ingredients" do |t|
      t.string "name"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    create_table "inventories" do |t|
      t.integer "startinginventory"
      t.integer "currentinventory"
      t.integer "resethour"
      t.bigint "menuitem_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["menuitem_id"], name: "index_inventories_on_menuitem_id"
    end
    create_table "menuavailabilities" do |t|
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
      t.index ["menu_id"], name: "index_menuavailabilities_on_menu_id"
    end
    create_table "menuitem_allergyn_mappings" do |t|
      t.bigint "menuitem_id", null: false
      t.bigint "allergyn_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["allergyn_id"], name: "index_menuitem_allergyn_mappings_on_allergyn_id"
      t.index ["menuitem_id"], name: "index_menuitem_allergyn_mappings_on_menuitem_id"
    end
    create_table "menuitem_ingredient_mappings" do |t|
      t.bigint "menuitem_id", null: false
      t.bigint "ingredient_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["ingredient_id"], name: "index_menuitem_ingredient_mappings_on_ingredient_id"
      t.index ["menuitem_id"], name: "index_menuitem_ingredient_mappings_on_menuitem_id"
    end
    create_table "menuitem_size_mappings" do |t|
      t.bigint "menuitem_id", null: false
      t.bigint "size_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["menuitem_id"], name: "index_menuitem_size_mappings_on_menuitem_id"
      t.index ["size_id"], name: "index_menuitem_size_mappings_on_size_id"
    end
    create_table "menuitem_tag_mappings" do |t|
      t.bigint "menuitem_id", null: false
      t.bigint "tag_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["menuitem_id"], name: "index_menuitem_tag_mappings_on_menuitem_id"
      t.index ["tag_id"], name: "index_menuitem_tag_mappings_on_tag_id"
    end
    create_table "menuitems" do |t|
      t.string "name"
      t.text "description"
      t.string "image"
      t.integer "status"
      t.integer "sequence"
      t.integer "calories"
      t.float "price"
      t.bigint "menusection_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["menusection_id"], name: "index_menuitems_on_menusection_id"
    end
    create_table "menus" do |t|
      t.string "name"
      t.text "description"
      t.string "image"
      t.integer "status"
      t.integer "sequence"
      t.bigint "restaurant_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["restaurant_id"], name: "index_menus_on_restaurant_id"
    end
    create_table "menusections" do |t|
      t.string "name"
      t.text "description"
      t.string "image"
      t.integer "status"
      t.integer "sequence"
      t.bigint "menu_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["menu_id"], name: "index_menusections_on_menu_id"
    end
    create_table "noticed_events" do |t|
      t.string "type"
      t.string "record_type"
      t.bigint "record_id"
      t.jsonb "params"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "notifications_count"
      t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
    end
    create_table "noticed_notifications" do |t|
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
    create_table "ordractions" do |t|
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
    create_table "ordritemnotes" do |t|
      t.string "note"
      t.bigint "ordritem_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["ordritem_id"], name: "index_ordritemnotes_on_ordritem_id"
    end
    create_table "ordritems" do |t|
      t.bigint "ordr_id", null: false
      t.bigint "menuitem_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.float "ordritemprice", default: 0.0
      t.index ["menuitem_id"], name: "index_ordritems_on_menuitem_id"
      t.index ["ordr_id"], name: "index_ordritems_on_ordr_id"
    end
    create_table "ordrparticipants" do |t|
      t.string "sessionid"
      t.integer "role"
      t.bigint "employee_id"
      t.bigint "ordr_id", null: false
      t.bigint "ordritem_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.index ["employee_id"], name: "index_ordrparticipants_on_employee_id"
      t.index ["ordr_id"], name: "index_ordrparticipants_on_ordr_id"
      t.index ["ordritem_id"], name: "index_ordrparticipants_on_ordritem_id"
    end
    create_table "ordrs" do |t|
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
      t.index ["employee_id"], name: "index_ordrs_on_employee_id"
      t.index ["menu_id"], name: "index_ordrs_on_menu_id"
      t.index ["restaurant_id"], name: "index_ordrs_on_restaurant_id"
      t.index ["tablesetting_id"], name: "index_ordrs_on_tablesetting_id"
    end
    create_table "restaurantavailabilities" do |t|
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
      t.index ["restaurant_id"], name: "index_restaurantavailabilities_on_restaurant_id"
    end
    create_table "restaurants" do |t|
      t.string "name"
      t.text "description"
      t.string "address1"
      t.string "address2"
      t.string "state"
      t.string "city"
      t.string "postcode"
      t.string "country"
      t.string "image"
      t.integer "status"
      t.integer "capacity"
      t.bigint "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "genid"
      t.index ["user_id"], name: "index_restaurants_on_user_id"
    end
    create_table "services" do |t|
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
    create_table "sizes" do |t|
      t.integer "size"
      t.string "name"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    create_table "tablesettings" do |t|
      t.string "name"
      t.text "description"
      t.integer "status"
      t.integer "capacity"
      t.bigint "restaurant_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "tabletype"
      t.index ["restaurant_id"], name: "index_tablesettings_on_restaurant_id"
    end
    create_table "tags" do |t|
      t.string "name"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "typs"
    end
    create_table "taxes" do |t|
      t.string "name"
      t.integer "taxtype"
      t.float "taxpercentage"
      t.bigint "restaurant_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "sequence"
      t.index ["restaurant_id"], name: "index_taxes_on_restaurant_id"
    end
    create_table "users" do |t|
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
      t.index ["email"], name: "index_users_on_email", unique: true
      t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    end
    add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
    add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
    add_foreign_key "employees", "restaurants"
    add_foreign_key "employees", "users"
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
    add_foreign_key "menuitems", "menusections"
    add_foreign_key "menus", "restaurants"
    add_foreign_key "menusections", "menus"
    add_foreign_key "ordractions", "ordritems"
    add_foreign_key "ordractions", "ordrparticipants"
    add_foreign_key "ordractions", "ordrs"
    add_foreign_key "ordritemnotes", "ordritems"
    add_foreign_key "ordritems", "menuitems"
    add_foreign_key "ordritems", "ordrs"
    add_foreign_key "ordrparticipants", "employees"
    add_foreign_key "ordrparticipants", "ordritems"
    add_foreign_key "ordrparticipants", "ordrs"
    add_foreign_key "ordrs", "employees"
    add_foreign_key "ordrs", "menus"
    add_foreign_key "ordrs", "restaurants"
    add_foreign_key "ordrs", "tablesettings"
    add_foreign_key "restaurantavailabilities", "restaurants"
    add_foreign_key "restaurants", "users"
    add_foreign_key "services", "users"
    add_foreign_key "tablesettings", "restaurants"
    add_foreign_key "taxes", "restaurants"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end

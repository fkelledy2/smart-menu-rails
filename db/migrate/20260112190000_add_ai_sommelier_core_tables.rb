class AddAiSommelierCoreTables < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :product_type, null: false
      t.string :canonical_name, null: false
      t.jsonb :attributes_json, null: false, default: {}
      t.timestamps
    end

    add_index :products, [:product_type, :canonical_name], unique: true

    create_table :menu_item_product_links do |t|
      t.references :menuitem, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :resolution_confidence, precision: 5, scale: 4
      t.text :explanations
      t.boolean :locked, null: false, default: false
      t.timestamps
    end

    add_index :menu_item_product_links, [:menuitem_id, :product_id], unique: true

    create_table :product_enrichments do |t|
      t.references :product, null: false, foreign_key: true
      t.string :source, null: false
      t.string :external_id
      t.jsonb :payload_json, null: false, default: {}
      t.datetime :fetched_at
      t.datetime :expires_at
      t.timestamps
    end

    add_index :product_enrichments, [:product_id, :source]
    add_index :product_enrichments, [:source, :external_id]

    create_table :beverage_pipeline_runs do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.string :status, null: false, default: 'running'
      t.string :current_step
      t.text :error_summary
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :items_processed, null: false, default: 0
      t.integer :needs_review_count, null: false, default: 0
      t.integer :unresolved_count, null: false, default: 0
      t.timestamps
    end

    add_index :beverage_pipeline_runs, [:menu_id, :status]

    change_table :menuitems do |t|
      t.string :sommelier_category
      t.decimal :sommelier_classification_confidence, precision: 5, scale: 4
      t.jsonb :sommelier_parsed_fields, null: false, default: {}
      t.decimal :sommelier_parse_confidence, precision: 5, scale: 4
      t.boolean :sommelier_needs_review, null: false, default: false
    end

    add_index :menuitems, :sommelier_category
    add_index :menuitems, :sommelier_needs_review
  end
end

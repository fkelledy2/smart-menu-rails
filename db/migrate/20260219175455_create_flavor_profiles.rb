class CreateFlavorProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :flavor_profiles do |t|
      t.references :profilable, polymorphic: true, null: false
      t.string :tags, array: true, default: [], null: false
      t.jsonb :structure_metrics, default: {}, null: false
      t.column :embedding_vector, :vector, limit: 1024
      t.string :provenance
      t.timestamps
    end

    add_index :flavor_profiles, [:profilable_type, :profilable_id], unique: true,
              name: 'idx_flavor_profiles_profilable'
    add_index :flavor_profiles, :tags, using: :gin

    create_table :pairing_recommendations do |t|
      t.references :drink_menuitem, null: false, foreign_key: { to_table: :menuitems }
      t.references :food_menuitem, null: false, foreign_key: { to_table: :menuitems }
      t.decimal :complement_score, precision: 5, scale: 4, default: 0
      t.decimal :contrast_score, precision: 5, scale: 4, default: 0
      t.decimal :score, precision: 5, scale: 4, default: 0
      t.text :rationale
      t.jsonb :risk_flags, default: [], null: false
      t.string :pairing_type
      t.timestamps
    end

    add_index :pairing_recommendations,
              [:drink_menuitem_id, :food_menuitem_id],
              unique: true,
              name: 'idx_pairings_drink_food'

    create_table :similar_product_recommendations do |t|
      t.references :product, null: false, foreign_key: true
      t.references :recommended_product, null: false, foreign_key: { to_table: :products }
      t.decimal :score, precision: 5, scale: 4, default: 0
      t.text :rationale
      t.timestamps
    end

    add_index :similar_product_recommendations,
              [:product_id, :recommended_product_id],
              unique: true,
              name: 'idx_similar_products_pair'
  end
end

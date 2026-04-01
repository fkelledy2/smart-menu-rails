class CreatePricingModels < ActiveRecord::Migration[7.2]
  def change
    create_table :pricing_models do |t|
      t.string :version, null: false
      t.integer :status, null: false, default: 0
      t.datetime :effective_from
      t.string :currency, null: false, default: 'EUR'
      t.jsonb :inputs_json, null: false, default: {}
      t.jsonb :outputs_json, null: false, default: {}
      t.bigint :published_by_user_id
      t.datetime :published_at
      t.text :publish_reason

      t.timestamps
    end

    add_index :pricing_models, :version, unique: true
    add_index :pricing_models, :status
    add_index :pricing_models, :effective_from
  end
end

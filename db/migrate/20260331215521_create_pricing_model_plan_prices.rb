class CreatePricingModelPlanPrices < ActiveRecord::Migration[7.2]
  def change
    create_table :pricing_model_plan_prices do |t|
      t.bigint :pricing_model_id, null: false
      t.bigint :plan_id, null: false
      t.string :interval, null: false, default: 'month'
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: 'EUR'
      t.string :stripe_price_id

      t.timestamps
    end

    add_index :pricing_model_plan_prices,
              %i[pricing_model_id plan_id interval currency],
              unique: true,
              name: 'index_pmpp_unique'
    add_index :pricing_model_plan_prices, :pricing_model_id
    add_index :pricing_model_plan_prices, :plan_id
    add_foreign_key :pricing_model_plan_prices, :pricing_models, on_delete: :cascade
    add_foreign_key :pricing_model_plan_prices, :plans, on_delete: :cascade
  end
end

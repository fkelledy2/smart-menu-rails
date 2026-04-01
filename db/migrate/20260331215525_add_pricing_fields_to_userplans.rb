class AddPricingFieldsToUserplans < ActiveRecord::Migration[7.2]
  def change
    add_column :userplans, :pricing_model_id, :bigint
    add_column :userplans, :applied_price_cents, :integer
    add_column :userplans, :applied_currency, :string
    add_column :userplans, :applied_interval, :string
    add_column :userplans, :applied_stripe_price_id, :string
    add_column :userplans, :pricing_override_keep_original_cohort, :boolean, default: false, null: false
    add_column :userplans, :pricing_override_by_user_id, :bigint
    add_column :userplans, :pricing_override_at, :datetime
    add_column :userplans, :pricing_override_reason, :text

    add_index :userplans, :pricing_model_id
    add_foreign_key :userplans, :pricing_models, column: :pricing_model_id
  end
end

class AddStripePriceIdsToPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :plans, :stripe_price_id_month, :string
    add_column :plans, :stripe_price_id_year, :string

    add_index :plans, :stripe_price_id_month
    add_index :plans, :stripe_price_id_year
  end
end

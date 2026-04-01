class CreateHerokuDynoSizeCosts < ActiveRecord::Migration[7.2]
  def change
    create_table :heroku_dyno_size_costs do |t|
      t.string :dyno_size, null: false
      t.integer :cost_cents_per_month, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :heroku_dyno_size_costs, :dyno_size, unique: true
  end
end

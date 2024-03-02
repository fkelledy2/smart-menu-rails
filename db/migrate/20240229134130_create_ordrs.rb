class CreateOrdrs < ActiveRecord::Migration[7.1]
  def change
    create_table :ordrs do |t|
      t.timestamp :orderedAt
      t.timestamp :deliveredAt
      t.timestamp :paidAt
      t.float :nett
      t.float :tip
      t.float :service
      t.float :tax
      t.float :gross
      t.references :employee, null: false, foreign_key: true
      t.references :tablesetting, null: false, foreign_key: true
      t.references :menu, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end

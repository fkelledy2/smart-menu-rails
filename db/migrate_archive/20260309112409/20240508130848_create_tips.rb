class CreateTips < ActiveRecord::Migration[7.1]
  def change
    create_table :tips do |t|
      t.float :percentage
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end

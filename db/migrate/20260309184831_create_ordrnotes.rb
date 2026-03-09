class CreateOrdrnotes < ActiveRecord::Migration[7.2]
  def change
    create_table :ordrnotes do |t|
      t.references :ordr, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :category, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.boolean :visible_to_kitchen, default: true
      t.boolean :visible_to_servers, default: true
      t.boolean :visible_to_customers, default: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :ordrnotes, [:ordr_id, :created_at]
    add_index :ordrnotes, [:category, :priority]
  end
end

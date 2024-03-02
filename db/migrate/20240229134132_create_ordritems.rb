class CreateOrdritems < ActiveRecord::Migration[7.1]
  def change
    create_table :ordritems do |t|
      t.references :ordr, null: false, foreign_key: true
      t.references :menuitem, null: false, foreign_key: true

      t.timestamps
    end
  end
end

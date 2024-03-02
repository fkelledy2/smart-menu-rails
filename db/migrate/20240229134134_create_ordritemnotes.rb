class CreateOrdritemnotes < ActiveRecord::Migration[7.1]
  def change
    create_table :ordritemnotes do |t|
      t.string :note
      t.references :ordritem, null: false, foreign_key: true

      t.timestamps
    end
  end
end

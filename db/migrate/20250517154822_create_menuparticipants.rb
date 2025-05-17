class CreateMenuparticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :menuparticipants do |t|
      t.string :sessionid
      t.string :preferredlocale
      t.references :smartmenu, null: false, foreign_key: true

      t.timestamps
    end
  end
end

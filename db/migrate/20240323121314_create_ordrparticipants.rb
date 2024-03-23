class CreateOrdrparticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :ordrparticipants do |t|
      t.string :sessionid
      t.integer :action
      t.integer :role
      t.references :employee, null: true, foreign_key: true
      t.references :ordr, null: false, foreign_key: true
      t.references :ordritem, null: true, foreign_key: true

      t.timestamps
    end
  end
end

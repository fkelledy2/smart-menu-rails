class CreateOrdractions < ActiveRecord::Migration[7.1]
  def change
    create_table :ordractions do |t|
      t.integer :action
      t.references :ordrparticipant, null: false, foreign_key: true
      t.references :ordr, null: false, foreign_key: true
      t.references :ordritem, null: true, foreign_key: true
      t.timestamps
    end
  end
end

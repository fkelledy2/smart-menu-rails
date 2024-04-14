class CreateOrdrparticipantAllergynFilters < ActiveRecord::Migration[7.1]
  def change
    create_table :ordrparticipant_allergyn_filters do |t|
      t.references :ordrparticipant, null: false, foreign_key: true
      t.references :allergyn, null: false, foreign_key: true

      t.timestamps
    end
  end
end

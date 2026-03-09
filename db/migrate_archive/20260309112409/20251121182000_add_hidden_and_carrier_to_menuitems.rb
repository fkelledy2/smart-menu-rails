class AddHiddenAndCarrierToMenuitems < ActiveRecord::Migration[7.0]
  def change
    change_table :menuitems, bulk: true do |t|
      t.boolean :hidden, default: false, null: false
      t.boolean :tasting_carrier, default: false, null: false
    end

    add_index :menuitems, :hidden
    add_index :menuitems, [:menusection_id, :tasting_carrier], name: 'index_menuitems_on_section_and_carrier'
  end
end

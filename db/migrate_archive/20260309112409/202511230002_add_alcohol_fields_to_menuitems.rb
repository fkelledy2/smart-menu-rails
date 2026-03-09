class AddAlcoholFieldsToMenuitems < ActiveRecord::Migration[7.0]
  def change
    add_column :menuitems, :alcoholic, :boolean, default: false, null: false
    add_column :menuitems, :abv, :decimal, precision: 5, scale: 2
    add_column :menuitems, :alcohol_classification, :string
    add_column :menuitems, :alcohol_notes, :text
    add_index :menuitems, :alcoholic
    add_index :menuitems, :alcohol_classification
  end
end

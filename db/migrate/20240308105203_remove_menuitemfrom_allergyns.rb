class RemoveMenuitemfromAllergyns < ActiveRecord::Migration[7.1]
  def change
    remove_column :allergyns, :menuitem_id, :string
  end
end

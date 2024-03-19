class AddSequenceToTaxes < ActiveRecord::Migration[7.1]
  def change
    add_column :taxes, :sequence, :integer
  end
end

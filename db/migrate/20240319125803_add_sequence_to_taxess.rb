class AddSequenceToTaxess < ActiveRecord::Migration[7.1]
  def change
    add_column :taxesses, :sequence, :integer
  end
end

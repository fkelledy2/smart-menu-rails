class BackfillMenuitemsAlcoholClassification < ActiveRecord::Migration[7.2]
  def up
    menuitems = Class.new(ActiveRecord::Base) do
      self.table_name = 'menuitems'
    end

    menuitems.where(alcohol_classification: [nil, '']).in_batches(of: 1000) do |batch|
      batch.update_all(alcohol_classification: 'non_alcoholic', abv: 0)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

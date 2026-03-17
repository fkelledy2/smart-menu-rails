class IngredientCsvImportService
  require 'csv'

  def initialize(restaurant)
    @restaurant = restaurant
  end

  def import(file)
    imported = 0
    skipped = 0
    errors = []

    CSV.foreach(file.path, headers: true) do |row|
      ingredient = @restaurant.ingredients.find_or_initialize_by(name: row['name'])
      
      ingredient.assign_attributes(
        category: row['category'],
        unit_of_measure: row['unit_of_measure'],
        current_cost_per_unit: row['cost_per_unit'],
        description: row['description'],
        is_shared: row['is_shared'] == 'true'
      )

      if ingredient.save
        imported += 1
      else
        skipped += 1
        errors << "Row #{imported + skipped}: #{ingredient.errors.full_messages.join(', ')}"
      end
    end

    { success: true, imported: imported, skipped: skipped, errors: errors }
  rescue => e
    { success: false, error: e.message }
  end
end

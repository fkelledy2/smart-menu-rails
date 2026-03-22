require 'test_helper'
require 'tempfile'

class IngredientCsvImportServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @service = IngredientCsvImportService.new(@restaurant)
  end

  def create_csv_file(content)
    file = Tempfile.new(['ingredients', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  test 'imports ingredients from CSV' do
    csv = create_csv_file(<<~CSV)
      name,category,unit_of_measure,cost_per_unit,description,is_shared
      Tomato,vegetable,kg,1.50,Fresh tomatoes,false
      Basil,herb,bunch,0.75,Fresh basil,false
    CSV

    result = @service.import(csv)

    assert result[:success]
    assert_equal 2, result[:imported]
    assert_equal 0, result[:skipped]
    assert_empty result[:errors]
  ensure
    csv.close
    csv.unlink
  end

  test 'updates existing ingredient with same name' do
    @restaurant.ingredients.create!(name: 'Tomato')

    csv = create_csv_file(<<~CSV)
      name,category,unit_of_measure,cost_per_unit,description,is_shared
      Tomato,vegetable,kg,2.00,Updated tomato,false
    CSV

    result = @service.import(csv)

    assert result[:success]
    assert_equal 1, result[:imported]
    ingredient = @restaurant.ingredients.find_by(name: 'Tomato')
    assert_in_delta 2.0, ingredient.current_cost_per_unit.to_f, 0.01
  ensure
    csv.close
    csv.unlink
  end

  test 'returns error result for invalid file' do
    # Pass a non-existent file path
    fake_file = OpenStruct.new(path: '/nonexistent/file.csv')
    result = @service.import(fake_file)

    assert_not result[:success]
    assert_not_nil result[:error]
  end

  test 'returns success with empty csv' do
    csv = create_csv_file("name,category,unit_of_measure,cost_per_unit,description,is_shared\n")

    result = @service.import(csv)

    assert result[:success]
    assert_equal 0, result[:imported]
    assert_equal 0, result[:skipped]
  ensure
    csv.close
    csv.unlink
  end

  test 'sets is_shared based on csv value' do
    csv = create_csv_file(<<~CSV)
      name,category,unit_of_measure,cost_per_unit,description,is_shared
      SharedItem,spice,g,0.10,A shared item,true
    CSV

    @service.import(csv)
    ingredient = @restaurant.ingredients.find_by(name: 'SharedItem')
    assert ingredient.is_shared
  ensure
    csv.close
    csv.unlink
  end

  test 'result hash has expected keys' do
    csv = create_csv_file("name,category,unit_of_measure,cost_per_unit,description,is_shared\n")
    result = @service.import(csv)

    assert_includes result.keys, :success
    assert_includes result.keys, :imported
    assert_includes result.keys, :skipped
    assert_includes result.keys, :errors
  ensure
    csv.close
    csv.unlink
  end
end

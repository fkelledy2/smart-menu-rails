require 'test_helper'

class EstablishmentTypeInferenceTest < ActiveSupport::TestCase
  def setup
    @service = EstablishmentTypeInference.new
  end

  # === infer_from_google_places_types ===

  test 'infers restaurant from google places types' do
    result = @service.infer_from_google_places_types(['restaurant', 'food'])
    assert_includes result, 'restaurant'
  end

  test 'infers bar from bar type' do
    result = @service.infer_from_google_places_types(['bar'])
    assert_includes result, 'bar'
  end

  test 'infers bar from night_club type' do
    result = @service.infer_from_google_places_types(['night_club'])
    assert_includes result, 'bar'
  end

  test 'infers wine_bar from wine_bar type' do
    result = @service.infer_from_google_places_types(['wine_bar'])
    assert_includes result, 'wine_bar'
  end

  test 'infers whiskey_bar from whiskey_bar type' do
    result = @service.infer_from_google_places_types(['whiskey_bar'])
    assert_includes result, 'whiskey_bar'
  end

  test 'returns empty array for empty types' do
    result = @service.infer_from_google_places_types([])
    assert_equal [], result
  end

  test 'returns empty array for nil types' do
    result = @service.infer_from_google_places_types(nil)
    assert_equal [], result
  end

  test 'returns only allowed types' do
    result = @service.infer_from_google_places_types(['restaurant', 'spa', 'lodging'])
    assert_equal ['restaurant'], result
  end

  test 'returns multiple types when applicable' do
    result = @service.infer_from_google_places_types(['bar', 'food', 'restaurant'])
    assert_includes result, 'bar'
    assert_includes result, 'restaurant'
  end

  test 'deduplicates results' do
    result = @service.infer_from_google_places_types(['restaurant', 'food'])
    assert_equal result.uniq, result
  end

  test 'handles mixed case types' do
    result = @service.infer_from_google_places_types(['Restaurant', 'BAR'])
    assert_includes result, 'restaurant'
    assert_includes result, 'bar'
  end

  # === infer_from_text ===

  test 'infers restaurant from text containing restaurant' do
    result = @service.infer_from_text('This is a great restaurant in the city')
    assert_includes result, 'restaurant'
  end

  test 'infers bar from text containing bar word' do
    result = @service.infer_from_text('Visit our bar for drinks')
    assert_includes result, 'bar'
  end

  test 'infers wine_bar from text containing wine' do
    result = @service.infer_from_text('Our wine selection is exceptional')
    assert_includes result, 'wine_bar'
  end

  test 'infers whiskey_bar from text containing whiskey' do
    result = @service.infer_from_text('We specialise in whiskey cocktails')
    assert_includes result, 'whiskey_bar'
  end

  test 'returns empty array for empty text' do
    result = @service.infer_from_text('')
    assert_equal [], result
  end

  test 'returns empty array for nil text' do
    result = @service.infer_from_text(nil)
    assert_equal [], result
  end

  test 'does not infer bar from word embedded in another word' do
    result = @service.infer_from_text('The establishment is near the harbour')
    assert_not_includes result, 'bar'
  end

  test 'is case insensitive for text' do
    result = @service.infer_from_text('Best RESTAURANT in town')
    assert_includes result, 'restaurant'
  end

  # === labels_for ===

  test 'returns labels for known types' do
    result = @service.labels_for(['restaurant', 'bar'])
    assert_includes result, 'Restaurant'
    assert_includes result, 'Bar'
  end

  test 'returns label for wine_bar' do
    result = @service.labels_for(['wine_bar'])
    assert_equal ['Wine bar'], result
  end

  test 'returns label for whiskey_bar' do
    result = @service.labels_for(['whiskey_bar'])
    assert_equal ['Whiskey bar'], result
  end

  test 'ignores unknown types in labels_for' do
    result = @service.labels_for(['restaurant', 'unknown_type'])
    assert_equal ['Restaurant'], result
  end

  test 'returns empty array for empty types in labels_for' do
    result = @service.labels_for([])
    assert_equal [], result
  end

  test 'handles symbol types in labels_for' do
    result = @service.labels_for([:restaurant])
    assert_equal ['Restaurant'], result
  end
end

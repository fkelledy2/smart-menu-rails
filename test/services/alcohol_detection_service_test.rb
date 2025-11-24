require 'test_helper'

class AlcoholDetectionServiceTest < ActiveSupport::TestCase
  test 'detects alcoholic by section hint and keyword' do
    det = AlcoholDetectionService.detect(section_name: 'Wines', item_name: 'Chardonnay', item_description: 'Glass 13%')
    assert det[:decided]
    assert_equal true, det[:alcoholic]
    assert_equal 'wine', det[:classification]
    assert_in_delta 13.0, det[:abv].to_f, 0.1
  end

  test 'detects non-alcoholic by negation' do
    det = AlcoholDetectionService.detect(section_name: 'Drinks', item_name: 'Non-alcoholic Beer', item_description: '0.0% Lager')
    assert det[:decided]
    assert_equal false, det[:alcoholic]
    assert_equal 'non_alcoholic', det[:classification]
  end

  test 'ambiguous item yields undecided with low confidence' do
    det = AlcoholDetectionService.detect(section_name: 'Snacks', item_name: 'House Special', item_description: 'Chef\'s choice')
    refute det[:decided]
    assert det[:confidence].to_f < 0.5
  end
end

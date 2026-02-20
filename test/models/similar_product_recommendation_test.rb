require 'test_helper'

class SimilarProductRecommendationTest < ActiveSupport::TestCase
  test 'can create a similar product recommendation' do
    p1 = Product.create!(product_type: 'whiskey', canonical_name: 'Lagavulin 16yo')
    p2 = Product.create!(product_type: 'whiskey', canonical_name: 'Laphroaig 10yo')

    rec = SimilarProductRecommendation.create!(
      product: p1,
      recommended_product: p2,
      score: 0.82,
      rationale: 'Similar flavor profile (82% match). Shared notes: smoke_peat, saline',
    )
    assert rec.persisted?
  end

  test 'enforces uniqueness on product pair' do
    p1 = Product.create!(product_type: 'whiskey', canonical_name: 'Talisker 10yo')
    p2 = Product.create!(product_type: 'whiskey', canonical_name: 'Highland Park 12yo')

    SimilarProductRecommendation.create!(product: p1, recommended_product: p2, score: 0.7)
    dup = SimilarProductRecommendation.new(product: p1, recommended_product: p2, score: 0.8)
    assert_not dup.valid?
  end

  test 'for_product scope returns recommendations for a product' do
    p1 = Product.create!(product_type: 'wine', canonical_name: 'Barolo 2018')
    p2 = Product.create!(product_type: 'wine', canonical_name: 'Brunello 2017')
    SimilarProductRecommendation.create!(product: p1, recommended_product: p2, score: 0.6)

    results = SimilarProductRecommendation.for_product(p1.id)
    assert_equal 1, results.count
    assert_equal p2.id, results.first.recommended_product_id
  end
end

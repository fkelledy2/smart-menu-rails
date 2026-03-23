require 'test_helper'

class ProductEnrichmentTest < ActiveSupport::TestCase
  def setup
    @product = Product.create!(product_type: 'whiskey', canonical_name: "Test Whiskey #{SecureRandom.hex(4)}")
    @enrichment = ProductEnrichment.new(product: @product, source: 'whisky_hunter')
  end

  test 'valid enrichment saves' do
    assert @enrichment.save
  end

  test 'requires source' do
    @enrichment.source = nil
    assert_not @enrichment.valid?
    assert_includes @enrichment.errors[:source], "can't be blank"
  end

  test 'belongs to product' do
    @enrichment.save!
    assert_equal @product, @enrichment.product
  end
end

require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  def setup
    @product = Product.new(
      product_type: 'whiskey',
      canonical_name: 'Glenfiddich 12',
    )
  end

  test 'valid product saves' do
    assert @product.save
  end

  test 'requires product_type' do
    @product.product_type = nil
    assert_not @product.valid?
    assert_includes @product.errors[:product_type], "can't be blank"
  end

  test 'requires canonical_name' do
    @product.canonical_name = nil
    assert_not @product.valid?
    assert_includes @product.errors[:canonical_name], "can't be blank"
  end

  test 'enforces uniqueness of canonical_name scoped to product_type' do
    @product.save!
    duplicate = Product.new(product_type: 'whiskey', canonical_name: 'Glenfiddich 12')
    assert_not duplicate.valid?
  end

  test 'allows same canonical_name for different product_type' do
    @product.save!
    other = Product.new(product_type: 'wine', canonical_name: 'Glenfiddich 12')
    assert other.valid?
  end

  test 'has many menu_item_product_links' do
    assert_respond_to @product, :menu_item_product_links
  end

  test 'has many product_enrichments' do
    assert_respond_to @product, :product_enrichments
  end
end

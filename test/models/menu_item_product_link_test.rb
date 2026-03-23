require 'test_helper'

class MenuItemProductLinkTest < ActiveSupport::TestCase
  def setup
    @menuitem = menuitems(:one)
    @product = Product.create!(product_type: 'wine', canonical_name: "Test Wine #{SecureRandom.hex(4)}")
    @link = MenuItemProductLink.new(menuitem: @menuitem, product: @product)
  end

  test 'valid link saves' do
    assert @link.save
  end

  test 'enforces uniqueness of menuitem_id scoped to product_id' do
    @link.save!
    duplicate = MenuItemProductLink.new(menuitem: @menuitem, product: @product)
    assert_not duplicate.valid?
  end

  test 'allows same product linked to different menuitems' do
    @link.save!
    other_item = menuitems(:burger)
    other_link = MenuItemProductLink.new(menuitem: other_item, product: @product)
    assert other_link.valid?
  end

  test 'belongs to menuitem' do
    @link.save!
    assert_equal @menuitem, @link.menuitem
  end

  test 'belongs to product' do
    @link.save!
    assert_equal @product, @link.product
  end
end

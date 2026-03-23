# frozen_string_literal: true

require 'test_helper'

class MenuItemSearchDocumentTest < ActiveSupport::TestCase
  test 'requires restaurant_id' do
    doc = MenuItemSearchDocument.new(locale: 'en', content_hash: 'abc')
    assert_not doc.valid?
    assert_includes doc.errors[:restaurant_id], "can't be blank"
  end

  test 'requires locale' do
    doc = MenuItemSearchDocument.new(restaurant_id: 1, content_hash: 'abc')
    assert_not doc.valid?
    assert_includes doc.errors[:locale], "can't be blank"
  end

  test 'requires content_hash' do
    doc = MenuItemSearchDocument.new(restaurant_id: 1, locale: 'en')
    assert_not doc.valid?
    assert_includes doc.errors[:content_hash], "can't be blank"
  end

  test 'belongs to menu' do
    assert MenuItemSearchDocument.reflect_on_association(:menu)
  end

  test 'belongs to menuitem' do
    assert MenuItemSearchDocument.reflect_on_association(:menuitem)
  end
end

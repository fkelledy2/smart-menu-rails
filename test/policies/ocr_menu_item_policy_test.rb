require 'test_helper'

# OcrMenuItemPolicy:
# update? — owner? checks record -> ocr_menu_section -> ocr_menu_import -> restaurant.user_id == user.id
class OcrMenuItemPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    # bruschetta -> starters_section -> completed_import -> restaurant one (user: one)
    @item = ocr_menu_items(:bruschetta)
  end

  test 'update is allowed for item owner' do
    policy = OcrMenuItemPolicy.new(@owner, @item)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = OcrMenuItemPolicy.new(@other_user, @item)
    assert_not policy.update?
  end

  test 'update is denied for nil user' do
    policy = OcrMenuItemPolicy.new(nil, @item)
    assert_not policy.update?
  end

  test 'inherits from ApplicationPolicy' do
    assert OcrMenuItemPolicy < ApplicationPolicy
  end
end

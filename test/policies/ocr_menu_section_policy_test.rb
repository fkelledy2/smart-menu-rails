require 'test_helper'

# OcrMenuSectionPolicy:
# update? — owner? (record.ocr_menu_import.restaurant.user_id == user.id) OR admin?
# Scope   — admin? sees all; else joins ocr_menu_import -> restaurant, filters by user_id
class OcrMenuSectionPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @admin = users(:admin)
    # starters_section belongs to completed_import which belongs to restaurant one (user: one)
    @section = ocr_menu_sections(:starters_section)
  end

  test 'update is allowed for section owner' do
    policy = OcrMenuSectionPolicy.new(@owner, @section)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = OcrMenuSectionPolicy.new(@other_user, @section)
    assert_not policy.update?
  end

  test 'update is allowed for admin user' do
    policy = OcrMenuSectionPolicy.new(@admin, @section)
    assert policy.update?
  end

  test 'scope returns all sections for admin' do
    scope = OcrMenuSectionPolicy::Scope.new(@admin, OcrMenuSection.all)
    # admin sees everything — count should be >= 1
    assert scope.resolve.count >= 1
  end

  test 'scope returns only owned sections for regular user' do
    scope = OcrMenuSectionPolicy::Scope.new(@owner, OcrMenuSection.all)
    result = scope.resolve
    assert result.count >= 1, 'owner should see at least one section'
    result.each do |s|
      assert_equal @owner.id, s.ocr_menu_import.restaurant.user_id
    end
  end

  test 'scope returns no sections for non-owner of any restaurant with imports' do
    scope = OcrMenuSectionPolicy::Scope.new(@other_user, OcrMenuSection.all)
    # users(:two) owns no restaurants with OCR imports in fixtures
    assert_empty scope.resolve
  end

  test 'inherits from ApplicationPolicy' do
    assert OcrMenuSectionPolicy < ApplicationPolicy
  end
end

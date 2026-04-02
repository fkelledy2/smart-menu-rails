# frozen_string_literal: true

require 'test_helper'

# Tests for agent-specific extensions on OcrMenuItem.
class OcrMenuItemAgentTest < ActiveSupport::TestCase
  def setup
    @item = ocr_menu_items(:bruschetta)
  end

  test 'validates confidence_score is between 0.0 and 1.0' do
    @item.confidence_score = 0.9
    assert @item.valid?

    @item.confidence_score = 1.5
    assert_not @item.valid?

    @item.confidence_score = -0.1
    assert_not @item.valid?
  end

  test 'allows nil confidence_score' do
    @item.confidence_score = nil
    assert @item.valid?
  end

  test 'validates agent_approval_status inclusion' do
    valid_statuses = OcrMenuItem::AGENT_APPROVAL_STATUSES
    valid_statuses.each do |status|
      @item.agent_approval_status = status
      assert @item.valid?, "Expected #{status} to be valid"
    end

    @item.agent_approval_status = 'invented_status'
    assert_not @item.valid?
  end

  test 'allergen_flagged? returns true when allergens present' do
    @item.allergens = ['gluten']
    assert @item.allergen_flagged?
  end

  test 'allergen_flagged? returns false when allergens empty' do
    @item.allergens = []
    assert_not @item.allergen_flagged?
  end

  test 'requires_agent_approval? when allergens present regardless of confidence' do
    @item.allergens = ['gluten']
    @item.confidence_score = 1.0
    assert @item.requires_agent_approval?
  end

  test 'requires_agent_approval? when confidence below threshold' do
    @item.allergens = []
    @item.confidence_score = 0.6
    assert @item.requires_agent_approval?
  end

  test 'requires_agent_approval? when confidence nil' do
    @item.allergens = []
    @item.confidence_score = nil
    assert @item.requires_agent_approval?
  end

  test 'does not require agent approval when no allergens and confidence >= 0.8' do
    @item.allergens = []
    @item.confidence_score = 0.95
    assert_not @item.requires_agent_approval?
  end

  test 'auto_approved scope returns only auto_approved items' do
    @item.update_column(:agent_approval_status, 'auto_approved')
    assert_includes OcrMenuItem.auto_approved, @item
    assert_not_includes OcrMenuItem.require_approval, @item
  end

  test 'require_approval scope returns only require_approval items' do
    @item.update_column(:agent_approval_status, 'require_approval')
    assert_includes OcrMenuItem.require_approval, @item
    assert_not_includes OcrMenuItem.auto_approved, @item
  end
end

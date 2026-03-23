# frozen_string_literal: true

require 'test_helper'

class OrdrSplitItemAssignmentTest < ActiveSupport::TestCase
  test 'belongs to ordr_split_plan' do
    assert OrdrSplitItemAssignment.reflect_on_association(:ordr_split_plan)
  end

  test 'belongs to ordr_split_payment' do
    assert OrdrSplitItemAssignment.reflect_on_association(:ordr_split_payment)
  end

  test 'belongs to ordritem' do
    assert OrdrSplitItemAssignment.reflect_on_association(:ordritem)
  end

  test 'validates uniqueness of ordritem_id scoped to ordr_split_plan_id' do
    reflection = OrdrSplitItemAssignment.validators_on(:ordritem_id).find do |v|
      v.is_a?(ActiveRecord::Validations::UniquenessValidator)
    end
    assert reflection, 'Expected uniqueness validator on ordritem_id'
    scope = Array(reflection.options[:scope])
    assert_includes scope, :ordr_split_plan_id
  end
end

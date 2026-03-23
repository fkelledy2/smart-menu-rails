# frozen_string_literal: true

require 'test_helper'

class EstimateOcrItemCostsJobTest < ActiveSupport::TestCase
  def setup
    @ocr_item = ocr_menu_items(:bruschetta)
  end

  test 'skips estimation when price is blank' do
    @ocr_item.update_column(:price, nil)
    estimated = false

    AiCostEstimatorService.stub(:new, -> { raise 'should not be called' }) do
      assert_nothing_raised do
        EstimateOcrItemCostsJob.new.perform(@ocr_item.id)
      end
    end

    # Verify no cost columns were set
    @ocr_item.reload
    assert_nil @ocr_item.estimated_ingredient_cost
  end

  test 'updates ocr_item with estimates when estimator returns data' do
    estimates = {
      ingredient_cost: 0.29,
      labor_cost: 0.25,
      packaging_cost: 0.04,
      overhead_cost: 0.10,
      confidence: 0.82,
      notes: 'test estimate',
    }

    fake_estimator = Object.new
    fake_estimator.define_singleton_method(:estimate_costs_for_menu_item) { |**_kwargs| estimates }

    AiCostEstimatorService.stub(:new, fake_estimator) do
      EstimateOcrItemCostsJob.new.perform(@ocr_item.id)
    end

    @ocr_item.reload
    assert_in_delta 0.29, @ocr_item.estimated_ingredient_cost.to_f, 0.001
    assert_in_delta 0.25, @ocr_item.estimated_labor_cost.to_f, 0.001
    assert_in_delta 0.82, @ocr_item.cost_estimation_confidence.to_f, 0.001
    assert_equal 'test estimate', @ocr_item.ai_cost_notes
  end

  test 'does not update ocr_item when estimator returns nil' do
    fake_estimator = Object.new
    fake_estimator.define_singleton_method(:estimate_costs_for_menu_item) { |**_kwargs| nil }

    AiCostEstimatorService.stub(:new, fake_estimator) do
      EstimateOcrItemCostsJob.new.perform(@ocr_item.id)
    end

    @ocr_item.reload
    assert_nil @ocr_item.estimated_ingredient_cost
  end

  test 'does not raise when ocr_item_id does not exist' do
    assert_nothing_raised do
      EstimateOcrItemCostsJob.new.perform(-999_999)
    end
  end

  test 'does not raise when estimator raises an error' do
    fake_estimator = Object.new
    fake_estimator.define_singleton_method(:estimate_costs_for_menu_item) { |**_kwargs| raise 'OpenAI timeout' }

    AiCostEstimatorService.stub(:new, fake_estimator) do
      assert_nothing_raised do
        EstimateOcrItemCostsJob.new.perform(@ocr_item.id)
      end
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      EstimateOcrItemCostsJob.perform_later(@ocr_item.id)
    end
  end
end

class EstimateOcrItemCostsJob < ApplicationJob
  queue_as :default

  def perform(ocr_menu_item_id)
    ocr_item = OcrMenuItem.find(ocr_menu_item_id)
    return if ocr_item.price.blank?

    estimator = AiCostEstimatorService.new
    estimates = estimator.estimate_costs_for_menu_item(
      name: ocr_item.name,
      description: ocr_item.description,
      price: ocr_item.price,
      category: ocr_item.ocr_menu_section&.name,
    )

    if estimates
      ocr_item.update!(
        estimated_ingredient_cost: estimates[:ingredient_cost],
        estimated_labor_cost: estimates[:labor_cost],
        estimated_packaging_cost: estimates[:packaging_cost],
        estimated_overhead_cost: estimates[:overhead_cost],
        cost_estimation_confidence: estimates[:confidence],
        ai_cost_notes: estimates[:notes],
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to estimate costs for OcrMenuItem #{ocr_menu_item_id}: #{e.message}")
  end
end

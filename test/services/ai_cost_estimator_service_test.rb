# frozen_string_literal: true

require 'test_helper'

class AiCostEstimatorServiceTest < ActiveSupport::TestCase
  # Build a stub OpenAI client that returns a canned chat response
  def mock_client_with_json(json_body)
    response = {
      'choices' => [
        {
          'message' => {
            'content' => json_body,
          },
        },
      ],
    }
    client = Object.new
    client.define_singleton_method(:chat) { |**_kwargs| response }
    client
  end

  def mock_client_error
    client = Object.new
    client.define_singleton_method(:chat) { |**_kwargs| raise 'OpenAI connection timeout' }
    client
  end

  # =========================================================================
  # estimate_costs_for_menu_item — happy path
  # =========================================================================

  test 'returns parsed cost hash for valid JSON response' do
    json = '{"ingredient_cost": 0.30, "labor_cost": 0.28, "packaging_cost": 0.05, "overhead_cost": 0.12, "confidence": 0.8, "notes": "Estimated"}'
    client = mock_client_with_json(json)
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Burger',
      description: 'Classic beef burger',
      price: 14.99,
      category: 'Mains',
    )

    assert_kind_of Hash, result
    assert_in_delta 0.30, result[:ingredient_cost], 0.001
    assert_in_delta 0.28, result[:labor_cost], 0.001
    assert_in_delta 0.05, result[:packaging_cost], 0.001
    assert_in_delta 0.12, result[:overhead_cost], 0.001
    assert_in_delta 0.8, result[:confidence], 0.001
    assert_equal 'Estimated', result[:notes]
  end

  test 'returns parsed cost hash when category is nil' do
    json = '{"ingredient_cost": 0.32, "labor_cost": 0.27, "packaging_cost": 0.04, "overhead_cost": 0.11, "confidence": 0.75, "notes": "No category"}'
    client = mock_client_with_json(json)
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Salad',
      description: nil,
      price: 9.50,
    )

    assert_kind_of Hash, result
    assert_in_delta 0.32, result[:ingredient_cost], 0.001
  end

  test 'extracts JSON embedded in surrounding prose' do
    json = 'Here is the estimate: {"ingredient_cost": 0.29, "labor_cost": 0.26, "packaging_cost": 0.05, "overhead_cost": 0.10, "confidence": 0.7, "notes": "rough"} Hope that helps.'
    client = mock_client_with_json(json)
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Pizza',
      description: 'Margherita',
      price: 12.00,
    )

    assert_kind_of Hash, result
    assert_in_delta 0.29, result[:ingredient_cost], 0.001
  end

  # =========================================================================
  # parse_response — error paths
  # =========================================================================

  test 'returns nil when response content has no JSON object' do
    client = mock_client_with_json('Sorry, I cannot estimate that.')
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Mystery',
      description: nil,
      price: 5.00,
    )

    assert_nil result
  end

  test 'returns nil when response JSON is malformed' do
    client = mock_client_with_json('{invalid json here}')
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Soup',
      description: 'Tomato',
      price: 6.00,
    )

    assert_nil result
  end

  test 'returns nil when OpenAI client raises an error' do
    service = AiCostEstimatorService.new(openai_client: mock_client_error)

    result = service.estimate_costs_for_menu_item(
      name: 'Steak',
      description: 'Grilled',
      price: 35.00,
    )

    assert_nil result
  end

  # =========================================================================
  # result structure integrity
  # =========================================================================

  test 'result has all required keys' do
    json = '{"ingredient_cost": 0.31, "labor_cost": 0.25, "packaging_cost": 0.04, "overhead_cost": 0.10, "confidence": 0.82, "notes": "ok"}'
    client = mock_client_with_json(json)
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Fish',
      description: 'Grilled cod',
      price: 18.00,
    )

    %i[ingredient_cost labor_cost packaging_cost overhead_cost confidence notes].each do |key|
      assert result.key?(key), "Expected result to have key :#{key}"
    end
  end

  test 'cost values are Floats' do
    json = '{"ingredient_cost": 0.31, "labor_cost": 0.25, "packaging_cost": 0.04, "overhead_cost": 0.10, "confidence": 0.82, "notes": "test"}'
    client = mock_client_with_json(json)
    service = AiCostEstimatorService.new(openai_client: client)

    result = service.estimate_costs_for_menu_item(
      name: 'Chicken',
      description: 'Roasted',
      price: 16.00,
    )

    %i[ingredient_cost labor_cost packaging_cost overhead_cost confidence].each do |key|
      assert_kind_of Float, result[key], "Expected #{key} to be a Float"
    end
  end
end

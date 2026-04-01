# frozen_string_literal: true

require 'test_helper'

class CostInsights::TotalCalculatorTest < ActiveSupport::TestCase
  test 'calculates total from infra, vendor, and staff costs' do
    month = Date.current.beginning_of_month
    result = CostInsights::TotalCalculator.calculate(month: month, currency: 'EUR')

    assert_kind_of CostInsights::TotalCalculator::Result, result
    assert_equal month, result.month
    assert_equal 'EUR', result.currency
    assert result.total_cents >= 0
  end

  test 'total is sum of heroku + vendor + staff' do
    month = Date.current.beginning_of_month
    result = CostInsights::TotalCalculator.calculate(month: month, currency: 'EUR')

    assert_equal result.heroku_cents + result.vendor_cents + result.staff_cents,
                 result.total_cents
  end

  test 'total_euros is total_cents / 100' do
    month = Date.current.beginning_of_month
    result = CostInsights::TotalCalculator.calculate(month: month, currency: 'EUR')
    assert_equal result.total_cents / 100.0, result.total_euros
  end

  test 'breakdown includes all three cost categories' do
    month = Date.current.beginning_of_month
    result = CostInsights::TotalCalculator.calculate(month: month, currency: 'EUR')
    assert result.breakdown.key?(:heroku)
    assert result.breakdown.key?(:vendor)
    assert result.breakdown.key?(:staff)
  end

  test 'vendor total includes openai and deepl fixtures' do
    month = Date.current.beginning_of_month
    result = CostInsights::TotalCalculator.calculate(month: month, currency: 'EUR')
    # fixtures have openai: 8000 + deepl: 3000 = 11000
    assert result.vendor_cents >= 11_000
  end

  test 'staff total matches fixture' do
    month = Date.current.beginning_of_month
    result = CostInsights::TotalCalculator.calculate(month: month, currency: 'EUR')
    # fixture: 50000 + 150000 + 10000 = 210000
    assert_equal 210_000, result.staff_cents
  end
end

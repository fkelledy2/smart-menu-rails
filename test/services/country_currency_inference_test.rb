require 'test_helper'

class CountryCurrencyInferenceTest < ActiveSupport::TestCase
  def setup
    @service = CountryCurrencyInference.new
  end

  test 'infers USD for US' do
    assert_equal 'USD', @service.infer('US')
  end

  test 'infers GBP for GB' do
    assert_equal 'GBP', @service.infer('GB')
  end

  test 'infers EUR for IE' do
    assert_equal 'EUR', @service.infer('IE')
  end

  test 'infers EUR for DE' do
    assert_equal 'EUR', @service.infer('DE')
  end

  test 'infers EUR for FR' do
    assert_equal 'EUR', @service.infer('FR')
  end

  test 'infers CHF for CH' do
    assert_equal 'CHF', @service.infer('CH')
  end

  test 'infers CAD for CA' do
    assert_equal 'CAD', @service.infer('CA')
  end

  test 'infers AUD for AU' do
    assert_equal 'AUD', @service.infer('AU')
  end

  test 'infers JPY for JP' do
    assert_equal 'JPY', @service.infer('JP')
  end

  test 'infers SGD for SG' do
    assert_equal 'SGD', @service.infer('SG')
  end

  test 'is case-insensitive for lowercase country code' do
    assert_equal 'USD', @service.infer('us')
  end

  test 'is case-insensitive for mixed-case country code' do
    assert_equal 'GBP', @service.infer('Gb')
  end

  test 'strips whitespace from country code' do
    assert_equal 'USD', @service.infer('  US  ')
  end

  test 'returns nil for unknown country code' do
    assert_nil @service.infer('XX')
  end

  test 'returns nil for empty string' do
    assert_nil @service.infer('')
  end

  test 'returns nil for nil input' do
    assert_nil @service.infer(nil)
  end

  test 'handles EUR countries correctly' do
    eur_countries = %w[IE DE FR ES IT NL BE AT PT GR FI EE LV LT LU MT CY SI SK HR]
    eur_countries.each do |code|
      assert_equal 'EUR', @service.infer(code), "Expected EUR for #{code}"
    end
  end
end

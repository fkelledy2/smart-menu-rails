require 'test_helper'

class ReceiptTemplateRendererTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)

    # Set up totals so tests are deterministic
    @ordr.update_columns(
      gross: 24.97,
      tax: 2.25,
      tip: 2.00,
      nett: 20.72,
    )

    @renderer = ReceiptTemplateRenderer.new(@ordr)
  end

  # ---------------------------------------------------------------------------
  # receipt_items
  # ---------------------------------------------------------------------------

  test '#receipt_items returns non-removed ordritems' do
    items = @renderer.receipt_items
    assert items.all? { |i| i[:name].is_a?(String) }
    assert items.all? { |i| i[:quantity].is_a?(Integer) }
    assert items.all? { |i| i[:unit_price].is_a?(Float) }
    assert items.all? { |i| i[:line_total].is_a?(Float) }
  end

  # ---------------------------------------------------------------------------
  # Financial totals
  # ---------------------------------------------------------------------------

  test '#tax_amount returns ordr tax as float' do
    assert_equal 2.25, @renderer.tax_amount
  end

  test '#tip_amount returns ordr tip as float' do
    assert_equal 2.0, @renderer.tip_amount
  end

  test '#grand_total returns ordr gross as float' do
    assert_equal 24.97, @renderer.grand_total
  end

  test '#subtotal sums line totals' do
    expected = @renderer.receipt_items.sum { |i| i[:line_total] }
    assert_equal expected, @renderer.subtotal
  end

  # ---------------------------------------------------------------------------
  # Order metadata
  # ---------------------------------------------------------------------------

  test '#order_number returns ordr id as string' do
    assert_equal @ordr.id.to_s, @renderer.order_number
  end

  test '#order_date returns a formatted date string' do
    date = @renderer.order_date
    assert_match(/\d{2} \w+ \d{4}/, date)
  end

  test '#restaurant_name returns restaurant name' do
    assert_equal @restaurant.name, @renderer.restaurant_name
  end

  test '#restaurant_address concatenates available address fields' do
    @restaurant.update_columns(
      address1: '1 Test St',
      city: 'Dublin',
      postcode: 'D01 X1Y2',
      country: 'Ireland',
    )
    renderer = ReceiptTemplateRenderer.new(@ordr.reload)
    addr = renderer.restaurant_address
    assert_match('1 Test St', addr)
    assert_match('Dublin', addr)
  end

  test '#restaurant_address handles missing fields gracefully' do
    @restaurant.update_columns(address1: nil, city: nil, postcode: nil, country: nil)
    renderer = ReceiptTemplateRenderer.new(@ordr.reload)
    assert_equal '', renderer.restaurant_address
  end

  # ---------------------------------------------------------------------------
  # Currency formatting
  # ---------------------------------------------------------------------------

  test '#currency_symbol returns correct symbol for EUR' do
    @restaurant.update_column(:currency, 'EUR')
    renderer = ReceiptTemplateRenderer.new(@ordr)
    assert_equal '€', renderer.currency_symbol
  end

  test '#currency_symbol returns correct symbol for GBP' do
    @restaurant.update_column(:currency, 'GBP')
    renderer = ReceiptTemplateRenderer.new(@ordr)
    assert_equal '£', renderer.currency_symbol
  end

  test '#currency_symbol returns correct symbol for USD' do
    @restaurant.update_column(:currency, 'USD')
    renderer = ReceiptTemplateRenderer.new(@ordr)
    assert_equal '$', renderer.currency_symbol
  end

  test '#currency_symbol returns currency code for unknown currency' do
    @restaurant.update_column(:currency, 'XYZ')
    renderer = ReceiptTemplateRenderer.new(@ordr)
    assert_equal 'XYZ', renderer.currency_symbol
  end

  test '#format_currency includes the currency symbol and two decimal places' do
    @restaurant.update_column(:currency, 'EUR')
    renderer = ReceiptTemplateRenderer.new(@ordr)
    assert_equal '€12.50', renderer.format_currency(12.5)
  end

  # ---------------------------------------------------------------------------
  # Plain text output
  # ---------------------------------------------------------------------------

  test '#as_plain_text includes restaurant name' do
    assert_match @restaurant.name, @renderer.as_plain_text
  end

  test '#as_plain_text includes order number' do
    assert_match @ordr.id.to_s, @renderer.as_plain_text
  end

  test '#as_plain_text includes total' do
    text = @renderer.as_plain_text
    assert_match(/Total:/, text)
  end

  test '#as_plain_text includes thank-you message' do
    assert_match(/Thank you/, @renderer.as_plain_text)
  end
end

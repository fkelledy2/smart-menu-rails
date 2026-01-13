require 'test_helper'

class EnrichProductsJobTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant

    @menusection = menusections(:one)
    @menusection.update!(menu: @menu) if @menusection.menu != @menu

    @product = Product.create!(product_type: 'wine', canonical_name: 'Test Wine 2018')

    @menuitem = Menuitem.create!(
      menusection: @menusection,
      name: 'Test Wine 2018',
      description: 'Red wine',
      price: 10.0,
      calories: 0,
      preptime: 0,
      sequence: 999,
      status: 'active',
      itemtype: 'wine'
    )

    MenuItemProductLink.create!(menuitem: @menuitem, product: @product, resolution_confidence: 0.9)

    @run = BeveragePipelineRun.create!(
      restaurant: @restaurant,
      menu: @menu,
      status: 'running',
      started_at: Time.current,
      current_step: 'resolve_entities'
    )
  end

  test 'creates enrichment record using fallback when external providers not configured' do
    # Ensure OpenAI client not required for the test
    original = Rails.configuration.x.openai_client
    Rails.configuration.x.openai_client = nil

    assert_difference('ProductEnrichment.count', 1) do
      Menu::EnrichProductsJob.new.perform(@run.id, 'test')
    end

    enrichment = ProductEnrichment.order(:created_at).last
    assert_equal @product.id, enrichment.product_id
    assert_includes %w[openai whisky_hunter], enrichment.source
    assert enrichment.payload_json.is_a?(Hash)
  ensure
    Rails.configuration.x.openai_client = original
  end
end

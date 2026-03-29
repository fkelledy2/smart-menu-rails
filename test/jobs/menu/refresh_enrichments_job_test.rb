# frozen_string_literal: true

require 'test_helper'

class Menu::RefreshEnrichmentsJobTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test 'returns 0 when no stale enrichments exist' do
    result = Menu::RefreshEnrichmentsJob.new.perform(10)
    assert_equal 0, result
  end

  test 'returns early for non-existent run without error' do
    assert_nothing_raised do
      Menu::RefreshEnrichmentsJob.new.perform(0)
    end
  end

  test 'respects batch_size cap — processes at most batch_size enrichments' do
    product = Product.create!(product_type: 'whiskey', canonical_name: 'Test Whiskey Refresh', attributes_json: {})
    # Create 3 stale enrichments (all expired).
    3.times do |i|
      ProductEnrichment.create!(
        product: product,
        source: 'openai',
        payload_json: { note: "stub_#{i}" },
        fetched_at: 40.days.ago,
        expires_at: 35.days.ago,
      )
    end

    # Patch ensure_product_enrichment! on the Sidekiq job instance so no real
    # API calls are made. Minitest does not ship with any_instance — we patch
    # the private method at the class level for the duration of this test.
    called_with = []
    enrich_klass = Menu::EnrichProductsJob
    original = enrich_klass.instance_method(:ensure_product_enrichment!)
    enrich_klass.define_method(:ensure_product_enrichment!) { |p| called_with << p }

    result = Menu::RefreshEnrichmentsJob.new.perform(2)

    # Restore original implementation
    enrich_klass.define_method(:ensure_product_enrichment!, original)

    assert_equal 2, result, 'Should process exactly batch_size enrichments'
    assert_equal 2, called_with.size, 'Should call ensure_product_enrichment! exactly batch_size times'
  end
end

require 'test_helper'

class ProductEnrichmentRefreshJobTest < ActiveSupport::TestCase
  setup do
    @product = Product.create!(product_type: 'wine', canonical_name: 'Refresh Wine 2018')
    ProductEnrichment.create!(
      product: @product,
      source: 'openai',
      payload_json: { 'foo' => 'bar' },
      fetched_at: 40.days.ago,
      expires_at: 1.day.ago,
    )
  end

  test 'creates a new enrichment when existing is expired' do
    original = Rails.configuration.x.openai_client
    Rails.configuration.x.openai_client = nil

    assert_difference('ProductEnrichment.count', 1) do
      ProductEnrichmentRefreshJob.new.perform(10)
    end

    latest = ProductEnrichment.where(product_id: @product.id).order(created_at: :desc).first
    assert latest.expires_at > Time.current
  ensure
    Rails.configuration.x.openai_client = original
  end
end

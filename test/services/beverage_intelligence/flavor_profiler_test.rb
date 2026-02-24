require 'test_helper'

class BeverageIntelligence::FlavorProfilerTest < ActiveSupport::TestCase
  def setup
    @profiler = BeverageIntelligence::FlavorProfiler.new
  end

  test 'profile_product extracts tags from enrichment tasting notes' do
    product = Product.create!(product_type: 'whiskey', canonical_name: 'Lagavulin 16yo')
    ProductEnrichment.create!(
      product: product,
      source: 'openai',
      payload_json: {
        'tasting_notes' => {
          'nose' => 'Intense peat smoke, iodine, seaweed',
          'palate' => 'Rich, full-bodied, sweet with dried fruit and oak',
          'finish' => 'Long, smoky, warming with pepper spice',
        },
        'production_notes' => 'Distilled on Islay, aged 16 years in oak casks',
      },
      fetched_at: Time.current,
      expires_at: 30.days.from_now,
    )

    profile = @profiler.profile_product(product)
    assert profile.present?
    assert profile.is_a?(FlavorProfile)
    assert_includes profile.tags, 'smoke_peat'
    assert_includes profile.tags, 'sweet'
    assert_includes profile.tags, 'dried_fruit'
    assert_includes profile.tags, 'vanilla_oak'
    assert_includes profile.tags, 'spice'
    assert_equal 'rules_v1', profile.provenance
  end

  test 'profile_product returns nil without enrichment' do
    product = Product.create!(product_type: 'whiskey', canonical_name: 'Unknown Whiskey')
    assert_nil @profiler.profile_product(product)
  end

  test 'profile_food_item extracts food tags' do
    menuitem = menuitems(:one)
    menuitem.update_columns(name: 'Grilled Wagyu Steak', description: 'With truffle butter and roasted mushrooms')

    profile = @profiler.profile_food_item(menuitem)
    assert profile.present?
    assert_includes profile.tags, 'umami'
    assert_includes profile.tags, 'creamy'
    assert_includes profile.tags, 'earthy'
    assert profile.structure_metrics['body'].to_f > 0.5
  end

  test 'profile_food_item returns nil for blank text' do
    menuitem = menuitems(:one)
    menuitem.update_columns(name: '', description: '')
    assert_nil @profiler.profile_food_item(menuitem)
  end

  test 'profile_product_for_menuitem falls back to text rules' do
    menuitem = menuitems(:one)
    menuitem.update_columns(
      name: 'Smoky Islay Whisky',
      description: 'Peated single malt with vanilla and honey notes',
      itemtype: Menuitem.itemtypes[:whiskey],
    )

    profile = @profiler.profile_product_for_menuitem(menuitem)
    assert profile.present?
    assert_includes profile.tags, 'smoke_peat'
    assert_includes profile.tags, 'vanilla_oak'
    assert_equal 'text_rules_v1', profile.provenance
  end

  test 'estimate_drink_metrics detects body and sweetness from text' do
    product = Product.create!(product_type: 'wine', canonical_name: 'Barolo 2018')
    ProductEnrichment.create!(
      product: product,
      source: 'openai',
      payload_json: {
        'tasting_notes' => {
          'nose' => 'Rose, tar, cherry',
          'palate' => 'Full-bodied, tannic, with firm structure and dried cherry',
          'finish' => 'Long, persistent, with earthy notes',
        },
      },
      fetched_at: Time.current,
      expires_at: 30.days.from_now,
    )

    profile = @profiler.profile_product(product)
    assert profile.present?
    assert_includes profile.tags, 'tannic'
    assert_includes profile.tags, 'earthy'
    metrics = profile.structure_metrics
    assert metrics['body'].to_f >= 0.7, "Expected high body for full-bodied wine"
    assert metrics['tannin'].to_f >= 0.6, "Expected high tannin"
    assert metrics['finish_length'].to_f >= 0.7, "Expected long finish"
  end
end

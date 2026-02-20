require 'test_helper'

class FlavorProfileTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menusection = menusections(:one)
    @menuitem = menuitems(:one)
  end

  test 'can create a flavor profile for a menuitem' do
    profile = FlavorProfile.create!(
      profilable: @menuitem,
      tags: %w[sweet vanilla_oak],
      structure_metrics: { 'body' => 0.6, 'sweetness_level' => 0.7 },
      provenance: 'rules_v1',
    )
    assert profile.persisted?
    assert_equal 'Menuitem', profile.profilable_type
    assert_equal @menuitem.id, profile.profilable_id
  end

  test 'enforces uniqueness on profilable' do
    FlavorProfile.create!(
      profilable: @menuitem,
      tags: %w[sweet],
      structure_metrics: {},
      provenance: 'rules_v1',
    )
    duplicate = FlavorProfile.new(
      profilable: @menuitem,
      tags: %w[spice],
      structure_metrics: {},
      provenance: 'rules_v1',
    )
    assert_not duplicate.valid?
  end

  test 'tag_list returns comma-separated tags' do
    profile = FlavorProfile.new(tags: %w[sweet smoke_peat citrus])
    assert_equal 'sweet, smoke_peat, citrus', profile.tag_list
  end

  test 'CONTROLLED_TAGS includes expected values' do
    assert_includes FlavorProfile::CONTROLLED_TAGS, 'sweet'
    assert_includes FlavorProfile::CONTROLLED_TAGS, 'smoke_peat'
    assert_includes FlavorProfile::CONTROLLED_TAGS, 'vanilla_oak'
    assert_includes FlavorProfile::CONTROLLED_TAGS, 'tannic'
  end

  test 'scopes filter by profilable_type' do
    FlavorProfile.create!(profilable: @menuitem, tags: %w[sweet], structure_metrics: {}, provenance: 'test')
    assert_equal 1, FlavorProfile.for_menuitems.count
    assert_equal 0, FlavorProfile.for_products.count
  end
end

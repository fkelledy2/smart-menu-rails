require 'test_helper'

class MenuVersionSnapshotServiceTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  test 'raises ArgumentError when menu is nil' do
    assert_raises(ArgumentError) do
      MenuVersionSnapshotService.snapshot_for(nil)
    end
  end

  test 'returns a hash with expected top-level keys' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    assert_kind_of Hash, result
    assert_includes result.keys, :schema_version
    assert_includes result.keys, :menu
    assert_includes result.keys, :menuavailabilities
    assert_includes result.keys, :menusections
  end

  test 'includes schema_version constant' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    assert_equal MenuVersionSnapshotService::SCHEMA_VERSION, result[:schema_version]
  end

  test 'menu snapshot has expected keys' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    menu_snapshot = result[:menu]
    assert_kind_of Hash, menu_snapshot
    assert_includes menu_snapshot.keys, :id
    assert_includes menu_snapshot.keys, :name
    assert_includes menu_snapshot.keys, :description
    assert_includes menu_snapshot.keys, :status
    assert_includes menu_snapshot.keys, :sequence
    assert_includes menu_snapshot.keys, :displayImages
    assert_includes menu_snapshot.keys, :allowOrdering
  end

  test 'menu snapshot id matches the menu' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    assert_equal @menu.id, result[:menu][:id]
  end

  test 'menuavailabilities is an array' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    assert_kind_of Array, result[:menuavailabilities]
  end

  test 'menusections is an array' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    assert_kind_of Array, result[:menusections]
  end

  test 'snapshot includes sections with menuitems key' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    result[:menusections].each do |section|
      assert_includes section.keys, :menuitems
      assert_kind_of Array, section[:menuitems]
    end
  end

  test 'section snapshot has expected keys' do
    # Use ordering_menu which has real sections
    menu = menus(:ordering_menu)
    result = MenuVersionSnapshotService.snapshot_for(menu)

    result[:menusections].each do |section|
      assert_includes section.keys, :id
      assert_includes section.keys, :name
      assert_includes section.keys, :sequence
      assert_includes section.keys, :status
      assert_includes section.keys, :menuitems
    end
  end

  test 'item snapshot has expected keys when items exist' do
    menu = menus(:ordering_menu)
    result = MenuVersionSnapshotService.snapshot_for(menu)

    result[:menusections].each do |section|
      section[:menuitems].each do |item|
        assert_includes item.keys, :id
        assert_includes item.keys, :name
        assert_includes item.keys, :price
        assert_includes item.keys, :sequence
        assert_includes item.keys, :status
      end
    end
  end

  test 'snapshot is JSON-serializable' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    assert_nothing_raised do
      JSON.generate(result)
    end
  end

  test 'can reconstruct snapshot from JSON' do
    result = MenuVersionSnapshotService.snapshot_for(@menu)
    json_str = JSON.generate(result)
    parsed = JSON.parse(json_str)
    assert_equal @menu.id, parsed['menu']['id']
  end
end

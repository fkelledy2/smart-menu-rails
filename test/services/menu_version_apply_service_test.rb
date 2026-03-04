require 'test_helper'

class MenuVersionApplyServiceTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:one)

    # Ensure menu has sections and items loaded
    @menu.menusections.reload
    @menu.menusections.each { |s| s.menuitems.reload }
  end

  test "apply_snapshot! preserves items not in snapshot" do
    section = @menu.menusections.first
    skip "No sections available for test" unless section

    all_items = section.menuitems.to_a
    skip "Need at least 2 items to test" if all_items.size < 2

    # Build a snapshot that only includes the FIRST item, simulating
    # a snapshot taken before the second item was added
    snapshot_item = all_items.first
    missing_item = all_items.last

    snapshot = {
      'menu' => { 'name' => @menu.name },
      'menusections' => [
        {
          'id' => section.id,
          'name' => section.name,
          'sequence' => section.sequence,
          'menuitems' => [
            { 'id' => snapshot_item.id, 'name' => snapshot_item.name, 'sequence' => 1 }
          ]
        }
      ]
    }

    # Create a fake menu version
    version = MenuVersion.new(snapshot_json: snapshot, version_number: 1)

    # Eager-load associations (required by the service)
    @menu.menusections.each { |s| s.association(:menuitems).loaded? || s.menuitems.load }

    MenuVersionApplyService.apply_snapshot!(menu: @menu, menu_version: version)

    result_items = section.menuitems.to_a
    result_ids = result_items.map(&:id)

    # Both items should be present — snapshot item first, then the missing one appended
    assert_includes result_ids, snapshot_item.id, "Snapshot item should be present"
    assert_includes result_ids, missing_item.id, "Item added after snapshot should still be present"
    assert_equal snapshot_item.id, result_ids.first, "Snapshot item should come first (snapshot ordering)"
  end

  test "apply_snapshot! preserves sections not in snapshot" do
    all_sections = @menu.menusections.to_a
    skip "Need at least 2 sections to test" if all_sections.size < 2

    snapshot_section = all_sections.first
    missing_section = all_sections.last

    snapshot = {
      'menu' => { 'name' => @menu.name },
      'menusections' => [
        {
          'id' => snapshot_section.id,
          'name' => snapshot_section.name,
          'sequence' => 1,
          'menuitems' => snapshot_section.menuitems.map { |i| { 'id' => i.id, 'name' => i.name } }
        }
      ]
    }

    version = MenuVersion.new(snapshot_json: snapshot, version_number: 1)

    @menu.menusections.each { |s| s.association(:menuitems).loaded? || s.menuitems.load }

    MenuVersionApplyService.apply_snapshot!(menu: @menu, menu_version: version)

    result_section_ids = @menu.menusections.map(&:id)

    assert_includes result_section_ids, snapshot_section.id, "Snapshot section should be present"
    assert_includes result_section_ids, missing_section.id, "Section added after snapshot should still be present"
    assert_equal snapshot_section.id, result_section_ids.first, "Snapshot section should come first"
  end

  test "apply_snapshot! with empty snapshot keeps all DB items" do
    section = @menu.menusections.first
    skip "No sections available for test" unless section

    original_count = section.menuitems.size

    snapshot = {
      'menu' => { 'name' => @menu.name },
      'menusections' => [
        {
          'id' => section.id,
          'name' => section.name,
          'menuitems' => [] # empty snapshot — no items recorded
        }
      ]
    }

    version = MenuVersion.new(snapshot_json: snapshot, version_number: 1)

    @menu.menusections.each { |s| s.association(:menuitems).loaded? || s.menuitems.load }

    MenuVersionApplyService.apply_snapshot!(menu: @menu, menu_version: version)

    assert_equal original_count, section.menuitems.size,
      "All DB items should be preserved when snapshot has no items"
  end
end

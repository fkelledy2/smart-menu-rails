require 'test_helper'

class MenuVersionDiffServiceTest < ActiveSupport::TestCase
  def build_version(snapshot_hash)
    OpenStruct.new(snapshot_json: snapshot_hash)
  end

  def base_snapshot
    {
      'menusections' => [
        {
          'id' => 1,
          'name' => 'Starters',
          'description' => 'Light bites',
          'sequence' => 1,
          'menuitems' => [
            { 'id' => 10, 'name' => 'Soup', 'price' => 8.0, 'sequence' => 1 },
            { 'id' => 11, 'name' => 'Salad', 'price' => 9.5, 'sequence' => 2 },
          ],
        },
        {
          'id' => 2,
          'name' => 'Mains',
          'description' => 'Main courses',
          'sequence' => 2,
          'menuitems' => [
            { 'id' => 20, 'name' => 'Steak', 'price' => 28.0, 'sequence' => 1 },
          ],
        },
      ],
    }
  end

  # === RAISES ===

  test 'raises ArgumentError when from_version is nil' do
    to_version = build_version(base_snapshot)
    assert_raises(ArgumentError, 'from_version is required') do
      MenuVersionDiffService.diff(from_version: nil, to_version: to_version)
    end
  end

  test 'raises ArgumentError when to_version is nil' do
    from_version = build_version(base_snapshot)
    assert_raises(ArgumentError, 'to_version is required') do
      MenuVersionDiffService.diff(from_version: from_version, to_version: nil)
    end
  end

  # === IDENTICAL SNAPSHOTS ===

  test 'returns empty diff for identical snapshots' do
    from_version = build_version(base_snapshot)
    to_version = build_version(base_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_empty result[:sections][:added]
    assert_empty result[:sections][:removed]
    assert_empty result[:sections][:changed]
    assert_empty result[:items][:added]
    assert_empty result[:items][:removed]
    assert_empty result[:items][:changed]
  end

  # === ADDED SECTION ===

  test 'detects added section' do
    from_version = build_version(base_snapshot)
    to_snapshot = base_snapshot.deep_dup
    to_snapshot['menusections'] << { 'id' => 3, 'name' => 'Desserts', 'sequence' => 3, 'menuitems' => [] }

    to_version = build_version(to_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_equal 1, result[:sections][:added].length
    assert_equal 3, result[:sections][:added][0][:id]
    assert_equal 'Desserts', result[:sections][:added][0][:name]
  end

  # === REMOVED SECTION ===

  test 'detects removed section' do
    from_version = build_version(base_snapshot)
    to_snapshot = base_snapshot.deep_dup
    to_snapshot['menusections'] = to_snapshot['menusections'].first(1)

    to_version = build_version(to_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_equal 1, result[:sections][:removed].length
    assert_equal 2, result[:sections][:removed][0][:id]
    assert_equal 'Mains', result[:sections][:removed][0][:name]
  end

  # === CHANGED SECTION ===

  test 'detects changed section name' do
    from_version = build_version(base_snapshot)
    to_snapshot = base_snapshot.deep_dup
    to_snapshot['menusections'][0]['name'] = 'Appetizers'

    to_version = build_version(to_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_equal 1, result[:sections][:changed].length
    changes = result[:sections][:changed][0][:changes]
    name_change = changes.find { |c| c[:field] == 'name' }
    assert_not_nil name_change
    assert_equal 'Starters', name_change[:from]
    assert_equal 'Appetizers', name_change[:to]
  end

  # === ADDED ITEM ===

  test 'detects added item' do
    from_version = build_version(base_snapshot)
    to_snapshot = base_snapshot.deep_dup
    to_snapshot['menusections'][0]['menuitems'] << { 'id' => 12, 'name' => 'Bread', 'price' => 4.0, 'sequence' => 3 }

    to_version = build_version(to_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_equal 1, result[:items][:added].length
    assert_equal 12, result[:items][:added][0][:id]
    assert_equal 'Bread', result[:items][:added][0][:name]
  end

  # === REMOVED ITEM ===

  test 'detects removed item' do
    from_version = build_version(base_snapshot)
    to_snapshot = base_snapshot.deep_dup
    to_snapshot['menusections'][0]['menuitems'] = [{ 'id' => 10, 'name' => 'Soup', 'price' => 8.0, 'sequence' => 1 }]

    to_version = build_version(to_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_equal 1, result[:items][:removed].length
    assert_equal 11, result[:items][:removed][0][:id]
    assert_equal 'Salad', result[:items][:removed][0][:name]
  end

  # === CHANGED ITEM ===

  test 'detects changed item price' do
    from_version = build_version(base_snapshot)
    to_snapshot = base_snapshot.deep_dup
    to_snapshot['menusections'][0]['menuitems'][0]['price'] = 10.0

    to_version = build_version(to_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_equal 1, result[:items][:changed].length
    changes = result[:items][:changed][0][:changes]
    price_change = changes.find { |c| c[:field] == 'price' }
    assert_not_nil price_change
    assert_equal 8.0, price_change[:from]
    assert_equal 10.0, price_change[:to]
  end

  # === EMPTY SNAPSHOTS ===

  test 'handles empty snapshots' do
    from_version = build_version({})
    to_version = build_version({})
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_empty result[:sections][:added]
    assert_empty result[:sections][:removed]
    assert_empty result[:items][:added]
    assert_empty result[:items][:removed]
  end

  test 'handles nil snapshot_json' do
    from_version = build_version(nil)
    to_version = build_version(nil)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_empty result[:sections][:added]
    assert_empty result[:items][:added]
  end

  # === RESULT STRUCTURE ===

  test 'diff result has sections and items top-level keys' do
    from_version = build_version(base_snapshot)
    to_version = build_version(base_snapshot)
    result = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    assert_includes result.keys, :sections
    assert_includes result.keys, :items
    assert_includes result[:sections].keys, :added
    assert_includes result[:sections].keys, :removed
    assert_includes result[:sections].keys, :changed
    assert_includes result[:items].keys, :added
    assert_includes result[:items].keys, :removed
    assert_includes result[:items].keys, :changed
  end
end

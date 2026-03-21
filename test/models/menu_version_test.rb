# frozen_string_literal: true

require 'test_helper'

class MenuVersionTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @user = users(:one)
  end

  # === VALIDATIONS ===

  test 'valid with required fields' do
    version = MenuVersion.new(
      menu: @menu,
      version_number: 99,
      snapshot_json: { schema_version: 1, menu: {} },
      is_active: false,
    )
    assert version.valid?, version.errors.full_messages.join(', ')
  end

  test 'invalid without version_number' do
    version = MenuVersion.new(menu: @menu, snapshot_json: { data: true }, is_active: false)
    assert_not version.valid?
    assert version.errors[:version_number].any?
  end

  test 'invalid without snapshot_json' do
    version = MenuVersion.new(menu: @menu, version_number: 1, is_active: false)
    # snapshot_json defaults to {} via DB default — set explicitly to nil
    version.snapshot_json = nil
    assert_not version.valid?
    assert version.errors[:snapshot_json].any?
  end

  test 'version_number must be unique per menu' do
    MenuVersion.create!(menu: @menu, version_number: 1, snapshot_json: { v: 1 }, is_active: false)
    dup = MenuVersion.new(menu: @menu, version_number: 1, snapshot_json: { v: 2 }, is_active: false)
    assert_not dup.valid?
    assert dup.errors[:version_number].any?
  end

  test 'same version_number is allowed on a different menu' do
    other_menu = menus(:two)
    MenuVersion.create!(menu: @menu, version_number: 1, snapshot_json: { v: 1 }, is_active: false)
    version = MenuVersion.new(menu: other_menu, version_number: 1, snapshot_json: { v: 1 }, is_active: false)
    assert version.valid?, version.errors.full_messages.join(', ')
  end

  # === IMMUTABILITY ===

  test 'menu_id is read-only after create' do
    version = MenuVersion.create!(menu: @menu, version_number: 1, snapshot_json: { v: 1 }, is_active: false)
    other_menu = menus(:two)
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      version.update!(menu_id: other_menu.id)
    end
  end

  test 'version_number is read-only after create' do
    version = MenuVersion.create!(menu: @menu, version_number: 1, snapshot_json: { v: 1 }, is_active: false)
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      version.update!(version_number: 99)
    end
  end

  test 'snapshot_json is read-only after create' do
    version = MenuVersion.create!(menu: @menu, version_number: 1, snapshot_json: { v: 1 }, is_active: false)
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      version.update!(snapshot_json: { v: 999 })
    end
  end

  # === create_from_menu! ===

  test 'create_from_menu! creates a version with sequential version numbers' do
    snapshot = { schema_version: 1, menu: { id: @menu.id } }
    MenuVersionSnapshotService.stub(:snapshot_for, snapshot) do
      v1 = MenuVersion.create_from_menu!(menu: @menu, user: @user)
      v2 = MenuVersion.create_from_menu!(menu: @menu, user: @user)

      assert_equal 1, v1.version_number
      assert_equal 2, v2.version_number
    end
  end

  test 'create_from_menu! persists the snapshot and user' do
    snapshot = { schema_version: 1, menu: { id: @menu.id } }
    MenuVersionSnapshotService.stub(:snapshot_for, snapshot) do
      version = MenuVersion.create_from_menu!(menu: @menu, user: @user)
      version.reload
      assert_equal @user, version.created_by_user
      assert_equal snapshot.deep_stringify_keys, version.snapshot_json
    end
  end

  test 'create_from_menu! raises ArgumentError without a menu' do
    assert_raises(ArgumentError) { MenuVersion.create_from_menu!(menu: nil) }
  end
end

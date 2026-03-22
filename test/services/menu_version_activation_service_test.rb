require 'test_helper'

class MenuVersionActivationServiceTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @user = users(:one)

    # Create a menu version with snapshot
    snapshot = { 'sections' => [], 'version' => 1 }.to_json
    @version_a = MenuVersion.create!(
      menu: @menu,
      version_number: 1,
      snapshot_json: snapshot,
      is_active: false,
    )
    @version_b = MenuVersion.create!(
      menu: @menu,
      version_number: 2,
      snapshot_json: snapshot,
      is_active: false,
    )
  end

  test 'activate! raises ArgumentError when menu_version is nil' do
    assert_raises(ArgumentError) do
      MenuVersionActivationService.activate!(menu_version: nil)
    end
  end

  test 'activate! sets is_active to true for the given version' do
    MenuVersionActivationService.activate!(menu_version: @version_a)
    assert @version_a.reload.is_active
  end

  test 'activate! deactivates other versions for the same menu' do
    @version_a.update_column(:is_active, true)
    MenuVersionActivationService.activate!(menu_version: @version_b)
    assert_not @version_a.reload.is_active
    assert @version_b.reload.is_active
  end

  test 'activate! clears starts_at and ends_at when activating immediately' do
    @version_a.update_columns(starts_at: 1.day.from_now, ends_at: 2.days.from_now)
    MenuVersionActivationService.activate!(menu_version: @version_a)
    @version_a.reload
    assert_nil @version_a.starts_at
    assert_nil @version_a.ends_at
    assert @version_a.is_active
  end

  test 'activate! with starts_at sets version as scheduled (not active)' do
    future_start = 1.day.from_now
    MenuVersionActivationService.activate!(menu_version: @version_a, starts_at: future_start)
    @version_a.reload
    assert_not @version_a.is_active
    assert_in_delta future_start.to_i, @version_a.starts_at.to_i, 2
  end

  test 'activate! with ends_at sets version as scheduled' do
    future_end = 2.days.from_now
    MenuVersionActivationService.activate!(menu_version: @version_a, ends_at: future_end)
    @version_a.reload
    assert_not @version_a.is_active
    assert_in_delta future_end.to_i, @version_a.ends_at.to_i, 2
  end

  test 'activate! returns the menu_version' do
    result = MenuVersionActivationService.activate!(menu_version: @version_a)
    assert_equal @version_a, result
  end

  test 'activate! does not deactivate versions from other menus' do
    other_menu = menus(:two)
    snapshot = { 'sections' => [] }.to_json
    other_version = MenuVersion.create!(
      menu: other_menu,
      version_number: 1,
      snapshot_json: snapshot,
      is_active: true,
    )

    MenuVersionActivationService.activate!(menu_version: @version_a)
    assert other_version.reload.is_active
  end
end

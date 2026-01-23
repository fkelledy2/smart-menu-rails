# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Menu Versions UI permissions', type: :request do
  let(:owner) { create(:user) }
  let(:restaurant) { create(:restaurant, user: owner) }
  let(:menu) { create(:menu, restaurant: restaurant, owner_restaurant: restaurant) }

  before do
    allow_any_instance_of(User).to receive(:needs_onboarding?).and_return(false)
    restaurant_menu = RestaurantMenu.find_or_create_by!(restaurant: restaurant, menu: menu)
    restaurant_menu.update!(status: 'active', sequence: 1)

    section = create(:menusection, menu: menu, sequence: 1)
    create(:menuitem, menusection: section, name: 'A', price: 10.0, sequence: 1)

    MenuVersion.create_from_menu!(menu: menu, user: owner)
    MenuVersion.create_from_menu!(menu: menu, user: owner)
  end

  def load_versions_section
    get edit_restaurant_menu_path(restaurant, menu, section: 'versions'), headers: { 'ACCEPT' => 'text/html' }
  end

  def load_diff_frame(from_version_id:, to_version_id:)
    get versions_diff_restaurant_menu_path(restaurant, menu),
        params: { from_version_id: from_version_id, to_version_id: to_version_id },
        headers: { 'ACCEPT' => 'text/html', 'Turbo-Frame' => 'menu_versions_diff' }
  end

  it 'shows snapshot JSON links to owner' do
    sign_in owner

    load_versions_section
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Diff (JSON)')

    versions = menu.menu_versions.order(version_number: :desc)
    load_diff_frame(from_version_id: versions.last.id, to_version_id: versions.first.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('View JSON')
  end

  it 'shows snapshot JSON links to manager' do
    manager_user = create(:user)
    create(:employee, user: manager_user, restaurant: restaurant, status: 'active', role: 'manager')

    sign_in manager_user

    load_versions_section
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Diff (JSON)')

    versions = menu.menu_versions.order(version_number: :desc)
    load_diff_frame(from_version_id: versions.last.id, to_version_id: versions.first.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('View JSON')
  end

  it 'does not allow staff to access versions UI' do
    staff_user = create(:user)
    create(:employee, user: staff_user, restaurant: restaurant, status: 'active', role: 'staff')

    sign_in staff_user

    load_versions_section
    expect(response).not_to have_http_status(:ok)

    versions = menu.menu_versions.order(version_number: :desc)
    load_diff_frame(from_version_id: versions.last.id, to_version_id: versions.first.id)
    expect(response).not_to have_http_status(:ok)
  end
end

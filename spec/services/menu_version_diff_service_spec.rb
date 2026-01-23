# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MenuVersionDiffService, type: :service do
  it 'detects added/removed items and changed fields' do
    user = create(:user)
    restaurant = create(:restaurant, user: user)
    menu = create(:menu, restaurant: restaurant)

    section = create(:menusection, menu: menu, sequence: 1)
    item_a = create(:menuitem, menusection: section, name: 'A', price: 10.0, sequence: 1)
    item_b = create(:menuitem, menusection: section, name: 'B', price: 20.0, sequence: 2)

    v1 = MenuVersion.create_from_menu!(menu: menu, user: user)

    item_a.update!(name: 'A2')
    item_b.update!(archived: true)
    create(:menuitem, menusection: section, name: 'C', price: 30.0, sequence: 3)

    v2 = MenuVersion.create_from_menu!(menu: menu, user: user)

    diff = described_class.diff(from_version: v1, to_version: v2)

    changed_item_ids = diff.dig(:items, :changed).map { |x| x[:id] }
    removed_item_ids = diff.dig(:items, :removed).map { |x| x[:id] }
    added_item_names = diff.dig(:items, :added).map { |x| x[:name] }

    expect(changed_item_ids).to include(item_a.id)
    expect(removed_item_ids).to include(item_b.id)
    expect(added_item_names).to include('C')

    changes_for_a = diff.dig(:items, :changed).find { |x| x[:id] == item_a.id }[:changes]
    changed_fields = changes_for_a.map { |c| c[:field] }
    expect(changed_fields).to include('name')
  end
end

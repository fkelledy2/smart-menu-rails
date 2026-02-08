# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MenuVersion do
  describe '.create_from_menu!' do
    it 'allocates sequential version_number per menu' do
      user = create(:user)
      restaurant = create(:restaurant, user: user)
      menu = create(:menu, restaurant: restaurant)

      create(:menusection, menu: menu, sequence: 2)
      create(:menusection, menu: menu, sequence: 1)

      v1 = described_class.create_from_menu!(menu: menu, user: user)
      v2 = described_class.create_from_menu!(menu: menu, user: user)

      expect(v1.version_number).to eq(1)
      expect(v2.version_number).to eq(2)
    end

    it 'stores a deterministic snapshot ordered by section/item sequence' do
      user = create(:user)
      restaurant = create(:restaurant, user: user)
      menu = create(:menu, restaurant: restaurant)

      section_b = create(:menusection, menu: menu, name: 'B', sequence: 2)
      section_a = create(:menusection, menu: menu, name: 'A', sequence: 1)

      create(:menuitem, menusection: section_b, name: 'b2', sequence: 2)
      create(:menuitem, menusection: section_b, name: 'b1', sequence: 1)
      create(:menuitem, menusection: section_a, name: 'a2', sequence: 2)
      create(:menuitem, menusection: section_a, name: 'a1', sequence: 1)

      version = described_class.create_from_menu!(menu: menu, user: user)
      snapshot = version.snapshot_json

      sections = snapshot.fetch('menusections')
      expect(sections.map { |s| s.fetch('name') }).to eq(%w[A B])

      a_items = sections.first.fetch('menuitems')
      b_items = sections.last.fetch('menuitems')

      expect(a_items.map { |i| i.fetch('name') }).to eq(%w[a1 a2])
      expect(b_items.map { |i| i.fetch('name') }).to eq(%w[b1 b2])
    end
  end

  describe 'activation selection' do
    it 'prefers windowed versions over default active version' do
      user = create(:user)
      restaurant = create(:restaurant, user: user)
      menu = create(:menu, restaurant: restaurant)

      v_default = described_class.create_from_menu!(menu: menu, user: user)
      MenuVersionActivationService.activate!(menu_version: v_default)

      v_window = described_class.create_from_menu!(menu: menu, user: user)
      now = Time.current
      MenuVersionActivationService.activate!(
        menu_version: v_window,
        starts_at: now - 5.minutes,
        ends_at: now + 5.minutes,
      )

      expect(menu.active_menu_version(at: now)&.id).to eq(v_window.id)
      expect(menu.active_menu_version(at: now + 10.minutes)&.id).to eq(v_default.id)
    end
  end
end

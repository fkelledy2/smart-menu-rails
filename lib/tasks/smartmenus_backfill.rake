# frozen_string_literal: true

namespace :smartmenus do
  desc 'Backfill missing Smartmenu records for existing tables. Usage: rake smartmenus:backfill_tables[restaurant_id]'
  task :backfill_tables, [:restaurant_id] => :environment do |_t, args|
    restaurant_id = args[:restaurant_id]

    if restaurant_id.blank?
      puts '❌ Please provide a restaurant_id: rake smartmenus:backfill_tables[1]'
      exit 1
    end

    restaurant = Restaurant.find_by(id: restaurant_id)
    unless restaurant
      puts "❌ Restaurant #{restaurant_id} not found"
      exit 1
    end

    puts "🔧 Backfilling Smartmenus for restaurant_id=#{restaurant.id} (#{restaurant.name})"

    menus = Menu.where(restaurant_id: restaurant.id)
    tables = Tablesetting.where(restaurant_id: restaurant.id)

    created = 0

    tables.find_each do |table|
      menus.find_each do |menu|
        sm = Smartmenu.find_or_create_by!(
          restaurant_id: restaurant.id,
          menu_id: menu.id,
          tablesetting_id: table.id
        ) do |record|
          record.slug = SecureRandom.uuid
        end
        created += 1 if sm.previously_new_record?
      end

      sm = Smartmenu.find_or_create_by!(
        restaurant_id: restaurant.id,
        menu_id: nil,
        tablesetting_id: table.id
      ) do |record|
        record.slug = SecureRandom.uuid
      end
      created += 1 if sm.previously_new_record?
    end

    puts "✅ Backfill complete. Created #{created} Smartmenu record(s)."
  end
end

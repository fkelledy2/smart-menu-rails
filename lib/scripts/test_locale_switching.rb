#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to verify locale switching functionality
# Run with: rails runner lib/scripts/test_locale_switching.rb

puts "=== Locale Switching Test Script ==="
puts

# Find test data
restaurant = Restaurant.first
unless restaurant
  puts "❌ No restaurant found. Create one first."
  exit 1
end

menu = restaurant.menus.first
unless menu
  puts "❌ No menu found for restaurant #{restaurant.name}. Create one first."
  exit 1
end

smartmenu = Smartmenu.where(restaurant: restaurant, menu: menu).first
unless smartmenu
  puts "❌ No smartmenu found. Create one first."
  exit 1
end

puts "✅ Found test data:"
puts "   Restaurant: #{restaurant.name}"
puts "   Menu: #{menu.name}"
puts "   Smartmenu: #{smartmenu.slug}"
puts

# Check restaurant locale configuration
puts "=== Restaurant Locale Configuration ==="
restaurant_locales = Restaurantlocale.where(restaurant: restaurant, status: 'active')
if restaurant_locales.empty?
  puts "❌ No active locales configured for this restaurant"
  exit 1
end

restaurant_locales.each do |rl|
  default_marker = rl.dfault ? "✅ DEFAULT" : ""
  puts "   #{rl.locale} - #{rl.language} #{default_marker}"
end
puts

# Check localization data
puts "=== Localization Data ==="
menusection = menu.menusections.first
if menusection
  puts "Testing with section: #{menusection.name}"
  
  restaurant_locales.each do |rl|
    locale = rl.locale.downcase
    
    # Test case-insensitive lookup
    locale_record = Menusectionlocale.where(menusection_id: menusection.id)
                                    .where('LOWER(locale) = ?', locale)
                                    .first
    
    if locale_record
      puts "   ✅ #{locale.upcase}: '#{locale_record.name}'"
    else
      puts "   ⚠️  #{locale.upcase}: No localization found (will use default: '#{menusection.name}')"
    end
  end
else
  puts "⚠️  No menu sections found"
end
puts

menuitem = menu.menusections.first&.menuitems&.first
if menuitem
  puts "Testing with item: #{menuitem.name}"
  
  restaurant_locales.each do |rl|
    locale = rl.locale.downcase
    
    # Test case-insensitive lookup
    locale_record = Menuitemlocale.where(menuitem_id: menuitem.id)
                                  .where('LOWER(locale) = ?', locale)
                                  .first
    
    if locale_record
      puts "   ✅ #{locale.upcase}: '#{locale_record.name}'"
    else
      puts "   ⚠️  #{locale.upcase}: No localization found (will use default: '#{menuitem.name}')"
    end
  end
else
  puts "⚠️  No menu items found"
end
puts

# Test restaurant.getLocale with case variations
puts "=== Testing restaurant.getLocale() ==="
['IT', 'it', 'en', 'EN'].each do |locale_variant|
  result = restaurant.getLocale(locale_variant)
  if result
    puts "   ✅ getLocale('#{locale_variant}') => #{result.locale} (#{result.language})"
  else
    puts "   ❌ getLocale('#{locale_variant}') => nil"
  end
end
puts

# Test menuparticipant creation and locale
puts "=== Testing Menuparticipant ==="
mp = Menuparticipant.create!(
  smartmenu: smartmenu,
  sessionid: "test_#{Time.now.to_i}",
  preferredlocale: 'IT'  # Uppercase to test normalization
)

puts "   Created menuparticipant with preferredlocale: 'IT'"
puts "   After save: '#{mp.preferredlocale}' (should be lowercase)"

if mp.preferredlocale == 'it'
  puts "   ✅ Locale normalization working"
else
  puts "   ❌ Locale normalization NOT working - expected 'it', got '#{mp.preferredlocale}'"
end

# Test localized name retrieval
if menusection
  localized_name = menusection.localised_name(mp.preferredlocale)
  puts "   Section localized name: '#{localized_name}'"
  
  rl = restaurant.getLocale(mp.preferredlocale)
  if rl&.dfault
    expected = menusection.name
  else
    mil = Menusectionlocale.where(menusection_id: menusection.id)
                          .where('LOWER(locale) = ?', mp.preferredlocale)
                          .first
    expected = mil ? mil.name : menusection.name
  end
  
  if localized_name == expected
    puts "   ✅ Localized name matches expected"
  else
    puts "   ❌ Expected '#{expected}', got '#{localized_name}'"
  end
end

# Cleanup
mp.destroy
puts "   Cleaned up test menuparticipant"
puts

puts "=== Summary ==="
puts "✅ All checks passed!" if restaurant_locales.any?
puts
puts "Next steps:"
puts "1. Visit: http://localhost:3000/smartmenus/#{smartmenu.slug}"
puts "2. Open browser DevTools (F12)"
puts "3. Click locale flag buttons"
puts "4. Watch Network tab for PATCH requests"
puts "5. Watch Console for ActionCable messages"
puts "6. Verify menu content changes language"
puts
puts "If content doesn't change:"
puts "- Check if Menuitemlocale records exist for your locale"
puts "- Check browser console for JavaScript errors"
puts "- Check Rails logs for Ruby errors"
puts "- See test/LOCALE_SWITCHING_DIAGNOSIS.md for detailed troubleshooting"

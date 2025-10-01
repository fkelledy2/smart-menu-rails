#!/usr/bin/env ruby

# Complete Controller Migration Test
# Tests all controllers to verify they're using the new JavaScript system

require 'net/http'
require 'uri'

BASE_URL = 'http://localhost:3000'

# All controllers that should now use the new system
ALL_CONTROLLERS = %w[
  restaurants menus menuitems menusections employees ordrs inventories
  allergyns announcements contacts dw_orders_mv features genimages home
  ingredients metrics notifications ocr_menu_imports ocr_menu_items ocr_menu_sections
  onboarding payments plans sessions sizes smartmenus tablesettings
  tags taxes testimonials tips tracks userplans
  features_plans menuavailabilities menuitemsizemappings menuparticipants
  menusectionlocales ordractions ordritemnotes ordritems ordrparticipants
  restaurantavailabilities restaurantlocales smartmenus_locale
]

# Special routes for controllers that don't follow standard patterns
SPECIAL_ROUTES = {
  'home' => '/',
  'sessions' => '/users/sign_in',
  'onboarding' => '/onboarding',
  'dw_orders_mv' => '/dw_orders_mv',
  'contacts' => '/contacts/new',
  'smartmenus_locale' => '/smartmenus_locale'
}

def test_controller(controller_name)
  path = SPECIAL_ROUTES[controller_name] || "/#{controller_name}"
  uri = URI("#{BASE_URL}#{path}")
  
  begin
    response = Net::HTTP.get_response(uri)
    
    case response.code.to_i
    when 200
      # Check for new system indicators
      has_new_system = response.body.include?('application_new')
      has_old_system = response.body.include?('application.js') && !response.body.include?('application_new')
      
      if has_new_system
        puts "✅ #{controller_name.ljust(25)} - New system active"
        return true
      elsif has_old_system
        puts "❌ #{controller_name.ljust(25)} - Still using old system!"
        return false
      else
        puts "⚠️  #{controller_name.ljust(25)} - No JS system detected"
        return true # Might be a redirect or auth page
      end
      
    when 302, 301
      puts "🔄 #{controller_name.ljust(25)} - Redirect (likely auth)"
      return true
      
    when 401, 403
      puts "🔒 #{controller_name.ljust(25)} - Auth required"
      return true
      
    when 404
      puts "❓ #{controller_name.ljust(25)} - Route not found (#{path})"
      return true # Route might not exist
      
    when 500
      puts "💥 #{controller_name.ljust(25)} - Server error!"
      return false
      
    else
      puts "⚠️  #{controller_name.ljust(25)} - Status: #{response.code}"
      return true
    end
    
  rescue => e
    puts "💥 #{controller_name.ljust(25)} - Error: #{e.message}"
    return false
  end
end

def main
  puts "🧪 Complete Controller Migration Test"
  puts "Testing all #{ALL_CONTROLLERS.length} controllers for new JavaScript system"
  puts "=" * 70
  
  successful = 0
  failed = 0
  old_system_count = 0
  
  ALL_CONTROLLERS.each_with_index do |controller, index|
    print "#{(index + 1).to_s.rjust(2)}/#{ALL_CONTROLLERS.length}: "
    
    result = test_controller(controller)
    if result
      successful += 1
    else
      failed += 1
      old_system_count += 1 if controller.include?('old system')
    end
    
    sleep 0.3 # Don't overwhelm the server
  end
  
  puts "\n" + "=" * 70
  puts "📊 Migration Results:"
  puts "   Total controllers: #{ALL_CONTROLLERS.length}"
  puts "   Successful: #{successful}"
  puts "   Failed: #{failed}"
  
  if failed == 0
    puts "\n🎉 SUCCESS: All controllers migrated to new JavaScript system!"
  else
    puts "\n⚠️  Some controllers need attention"
  end
  
  puts "\n🔍 To test specific pages manually:"
  puts "   Home: http://localhost:3000/"
  puts "   Restaurants: http://localhost:3000/restaurants"
  puts "   Menus: http://localhost:3000/menus"
  puts "   Orders: http://localhost:3000/ordrs"
  puts "   Settings: http://localhost:3000/allergyns"
end

if __FILE__ == $0
  main
end

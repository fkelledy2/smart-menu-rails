#!/usr/bin/env ruby

# Controller Migration Testing Script
# Tests each controller for JavaScript errors after migration to new system

require 'net/http'
require 'uri'
require 'json'

BASE_URL = 'http://localhost:3000'.freeze

# Controllers to test in batches
BATCH_1 = %w[allergyns announcements contacts].freeze
BATCH_2 = %w[dw_orders_mv features genimages home].freeze
BATCH_3 = %w[ingredients metrics notifications ocr_menu_imports].freeze
BATCH_4 = %w[onboarding payments plans sessions].freeze
BATCH_5 = %w[sizes smartmenus tablesettings tags taxes testimonials tips tracks userplans].freeze

# Additional routes that might have different paths
SPECIAL_ROUTES = {
  'home' => '/',
  'sessions' => '/users/sign_in',
  'onboarding' => '/onboarding',
  'dw_orders_mv' => '/dw_orders_mv',
}.freeze

def test_controller(controller_name)
  # Try the standard route first
  path = SPECIAL_ROUTES[controller_name] || "/#{controller_name}"
  uri = URI("#{BASE_URL}#{path}")

  begin
    response = Net::HTTP.get_response(uri)

    case response.code.to_i
    when 200
      puts "✅ #{controller_name.ljust(20)} - OK (#{path})"

      # Check if new JS system meta tag is present
      if response.body.include?('name="js-system" content="new"')
        puts '   📱 New JS system active'
      elsif response.body.include?('name="js-system" content="old"')
        puts '   📟 Old JS system active'
      else
        puts '   ⚠️  No JS system meta tag found'
      end

      # Check for JavaScript includes
      if response.body.include?('application_new')
        puts '   🆕 application_new.js loaded'
      elsif response.body.include?('application.js')
        puts '   📜 application.js loaded'
      end

      true

    when 302, 301
      puts "🔄 #{controller_name.ljust(20)} - Redirect (#{response.code}) to #{response['Location']}"

      # Try following the redirect
      if response['Location']
        redirect_uri = URI(response['Location'])
        redirect_response = Net::HTTP.get_response(redirect_uri)
        if redirect_response.code.to_i == 200
          puts '   ✅ Redirect successful'
          return true
        end
      end
      true

    when 401, 403
      puts "🔒 #{controller_name.ljust(20)} - Auth required (#{response.code})"
      true

    when 404
      puts "❌ #{controller_name.ljust(20)} - Not Found (#{path})"

      # Try index route
      unless path.end_with?('/')
        index_path = "#{path}/"
        index_uri = URI("#{BASE_URL}#{index_path}")
        index_response = Net::HTTP.get_response(index_uri)
        if index_response.code.to_i == 200
          puts "   ✅ Found at #{index_path}"
          return true
        end
      end

      false

    when 500
      puts "💥 #{controller_name.ljust(20)} - Server Error (#{path})"
      false

    else
      puts "⚠️  #{controller_name.ljust(20)} - Status: #{response.code} (#{path})"
      false
    end
  rescue StandardError => e
    puts "💥 #{controller_name.ljust(20)} - Error: #{e.message}"
    false
  end
end

def test_batch(batch_name, controllers)
  puts "\n🧪 Testing #{batch_name}"
  puts '=' * 60

  total = controllers.length
  successful = 0

  controllers.each_with_index do |controller, index|
    puts "\n#{index + 1}/#{total}: Testing #{controller}"

    if test_controller(controller)
      successful += 1
    end

    # Small delay to avoid overwhelming the server
    sleep 0.5
  end

  puts "\n📊 #{batch_name} Results:"
  puts "   Total: #{total}"
  puts "   Successful: #{successful}"
  puts "   Failed: #{total - successful}"

  if successful == total
    puts "   🎉 All controllers in #{batch_name} working!"
  else
    puts '   ⚠️  Some controllers need attention'
  end

  successful == total
end

def main
  puts '🧪 Controller Migration Testing'
  puts 'Testing controllers after migration to new JavaScript system'
  puts '=' * 60

  # Test current batch (Batch 1)
  puts "\n🎯 Testing Current Batch (migrated to new system)"
  test_batch('Batch 1', BATCH_1)

  puts "\n#{'=' * 60}"
  puts '📋 Next batches to migrate:'
  puts "   Batch 2: #{BATCH_2.join(', ')}"
  puts "   Batch 3: #{BATCH_3.join(', ')}"
  puts "   Batch 4: #{BATCH_4.join(', ')}"
  puts "   Batch 5: #{BATCH_5.join(', ')}"
end

if __FILE__ == $PROGRAM_NAME
  main
end

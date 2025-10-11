#!/usr/bin/env ruby

# Test script to verify nested routes are working correctly
require 'net/http'
require 'uri'

BASE_URL = 'http://localhost:3000'.freeze

def test_nested_route(resource_type, restaurant_id = 1)
  path = "/restaurants/#{restaurant_id}/#{resource_type}"
  uri = URI("#{BASE_URL}#{path}")

  begin
    response = Net::HTTP.get_response(uri)

    case response.code.to_i
    when 200
      puts "✅ #{path} - Working (200 OK)"
      true
    when 302, 301
      puts "🔄 #{path} - Redirect (#{response.code}) - likely auth required"
      true
    when 401, 403
      puts "🔒 #{path} - Auth required (#{response.code})"
      true
    when 404
      puts "❌ #{path} - Not Found (404)"
      false
    when 500
      puts "💥 #{path} - Server Error (500)"
      false
    else
      puts "⚠️  #{path} - Status: #{response.code}"
      false
    end
  rescue StandardError => e
    puts "💥 #{path} - Error: #{e.message}"
    false
  end
end

def test_old_standalone_routes
  puts "\n🧪 Testing old standalone routes (should not work):"

  %w[tips sizes taxes].each do |resource|
    path = "/#{resource}"
    uri = URI("#{BASE_URL}#{path}")

    begin
      response = Net::HTTP.get_response(uri)
      if response.code.to_i == 404
        puts "✅ #{path} - Correctly removed (404)"
      else
        puts "⚠️  #{path} - Still accessible (#{response.code})"
      end
    rescue StandardError => e
      puts "💥 #{path} - Error: #{e.message}"
    end
  end
end

def main
  puts '🧪 Testing Nested Routes Migration'
  puts '=' * 50

  puts "\n🎯 Testing new nested routes:"
  success_count = 0
  total_count = 0

  %w[tips sizes taxes].each do |resource|
    total_count += 1
    if test_nested_route(resource)
      success_count += 1
    end
  end

  test_old_standalone_routes

  puts "\n📊 Results:"
  puts "   Nested routes working: #{success_count}/#{total_count}"

  if success_count == total_count
    puts '   🎉 All nested routes are accessible!'
  else
    puts '   ⚠️  Some routes may need attention'
  end

  puts "\n📋 New route patterns:"
  puts '   Tips: /restaurants/:restaurant_id/tips'
  puts '   Sizes: /restaurants/:restaurant_id/sizes'
  puts '   Taxes: /restaurants/:restaurant_id/taxes'
end

if __FILE__ == $PROGRAM_NAME
  main
end

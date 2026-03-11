#!/usr/bin/env ruby
# Script to close all open orders in the database
# Usage: rails runner lib/scripts/close_all_open_orders.rb

puts "Closing all open orders..."
puts "Environment: #{Rails.env}"
puts ""

# Find all orders that are not in a closed state
# Based on the Ordr model, closed states typically include: 'paid', 'cancelled', 'completed'
open_statuses = ['opened', 'submitted', 'preparing', 'ready', 'billrequested']

open_orders = Ordr.where(status: open_statuses)

puts "Found #{open_orders.count} open orders"
puts ""

if open_orders.count == 0
  puts "No open orders to close."
  exit 0
end

# Confirm in production (safety check)
if Rails.env.production?
  puts "WARNING: You are running this in PRODUCTION!"
  puts "Type 'YES' to continue:"
  response = STDIN.gets.chomp
  unless response == 'YES'
    puts "Aborted."
    exit 1
  end
end

closed_count = 0
failed_count = 0

open_orders.find_each do |order|
  begin
    # Update order to 'paid' status (most common closed state)
    order.update!(status: 'paid')
    closed_count += 1
    print "."
  rescue StandardError => e
    failed_count += 1
    puts "\nFailed to close order ##{order.id}: #{e.message}"
  end
end

puts "\n"
puts "=" * 50
puts "Summary:"
puts "  Successfully closed: #{closed_count} orders"
puts "  Failed: #{failed_count} orders"
puts "=" * 50

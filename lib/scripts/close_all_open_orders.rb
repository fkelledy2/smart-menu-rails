#!/usr/bin/env ruby
# Script to close all open orders in the database
# Usage: rails runner lib/scripts/close_all_open_orders.rb

Rails.logger.debug 'Closing all open orders...'
Rails.logger.debug { "Environment: #{Rails.env}" }
Rails.logger.debug ''

# Find all orders that are not in a closed state
# Based on the Ordr model, closed states typically include: 'paid', 'cancelled', 'completed'
open_statuses = %w[opened submitted preparing ready billrequested]

open_orders = Ordr.where(status: open_statuses)

Rails.logger.debug { "Found #{open_orders.count} open orders" }
Rails.logger.debug ''

if open_orders.none?
  Rails.logger.debug 'No open orders to close.'
  return
end

# Confirm in production (safety check)
if Rails.env.production?
  Rails.logger.debug 'WARNING: You are running this in PRODUCTION!'
  Rails.logger.debug "Type 'YES' to continue:"
  response = $stdin.gets.chomp
  unless response == 'YES'
    Rails.logger.debug 'Aborted.'
    return
  end
end

closed_count = 0
failed_count = 0

open_orders.find_each do |order|
  # Update order to 'paid' status (most common closed state)
  order.update!(status: 'paid')
  closed_count += 1
  Rails.logger.debug '.'
rescue StandardError => e
  failed_count += 1
  Rails.logger.debug { "\nFailed to close order ##{order.id}: #{e.message}" }
end

Rails.logger.debug "\n"
Rails.logger.debug '=' * 50
Rails.logger.debug 'Summary:'
Rails.logger.debug { "  Successfully closed: #{closed_count} orders" }
Rails.logger.debug { "  Failed: #{failed_count} orders" }
Rails.logger.debug '=' * 50

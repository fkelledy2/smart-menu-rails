# frozen_string_literal: true

namespace :db do
  desc "Audit database indexes and identify missing foreign key indexes"
  task index_audit: :environment do
    puts "\n" + "="*80
    puts "DATABASE INDEX AUDIT"
    puts "="*80
    
    missing_indexes = []
    existing_indexes = []
    
    # Get all tables
    tables = ActiveRecord::Base.connection.tables.sort
    
    tables.each do |table|
      next if table == 'schema_migrations' || table == 'ar_internal_metadata'
      
      puts "\n📋 Table: #{table}"
      puts "-" * 80
      
      # Get all columns ending in _id (foreign keys)
      columns = ActiveRecord::Base.connection.columns(table)
      foreign_key_columns = columns.select { |c| c.name.end_with?('_id') }
      
      if foreign_key_columns.empty?
        puts "  ℹ️  No foreign key columns"
        next
      end
      
      foreign_key_columns.each do |column|
        # Check if index exists for this column
        indexes = ActiveRecord::Base.connection.indexes(table)
        has_index = indexes.any? { |i| i.columns.include?(column.name) || i.columns.first == column.name }
        
        if has_index
          index = indexes.find { |i| i.columns.include?(column.name) }
          puts "  ✅ #{column.name.ljust(30)} - Indexed (#{index.columns.join(', ')})"
          existing_indexes << { table: table, column: column.name, index: index.name }
        else
          puts "  ❌ #{column.name.ljust(30)} - MISSING INDEX"
          missing_indexes << { table: table, column: column.name }
        end
      end
    end
    
    # Summary
    puts "\n" + "="*80
    puts "SUMMARY"
    puts "="*80
    puts "✅ Existing indexes: #{existing_indexes.count}"
    puts "❌ Missing indexes:  #{missing_indexes.count}"
    
    if missing_indexes.any?
      puts "\n" + "="*80
      puts "RECOMMENDED MIGRATION"
      puts "="*80
      puts "\nRun: rails generate migration AddMissingIndexes"
      puts "\nThen add this to the migration:\n\n"
      
      puts "class AddMissingIndexes < ActiveRecord::Migration[7.0]"
      puts "  def change"
      missing_indexes.each do |mi|
        puts "    add_index :#{mi[:table]}, :#{mi[:column]} unless index_exists?(:#{mi[:table]}, :#{mi[:column]})"
      end
      puts "  end"
      puts "end"
      
      puts "\n" + "="*80
      puts "ESTIMATED IMPACT"
      puts "="*80
      puts "Adding these #{missing_indexes.count} indexes could improve query performance by 20-50%"
      puts "Especially for queries with JOINs and WHERE clauses on these columns"
    else
      puts "\n✅ All foreign key columns are properly indexed!"
    end
    
    # Check for common composite index opportunities
    puts "\n" + "="*80
    puts "COMPOSITE INDEX OPPORTUNITIES"
    puts "="*80
    
    composite_suggestions = [
      { table: 'menus', columns: ['restaurant_id', 'status'], reason: 'Common query: find active menus for restaurant' },
      { table: 'ordrs', columns: ['restaurant_id', 'status'], reason: 'Common query: find open orders for restaurant' },
      { table: 'ordrs', columns: ['tablesetting_id', 'status'], reason: 'Common query: find orders for table' },
      { table: 'menuitems', columns: ['menusection_id', 'sequence'], reason: 'Common query: ordered items in section' },
      { table: 'menusections', columns: ['menu_id', 'sequence'], reason: 'Common query: ordered sections in menu' }
    ]
    
    composite_suggestions.each do |suggestion|
      if ActiveRecord::Base.connection.table_exists?(suggestion[:table])
        has_composite = ActiveRecord::Base.connection.indexes(suggestion[:table]).any? do |idx|
          idx.columns == suggestion[:columns]
        end
        
        if has_composite
          puts "  ✅ #{suggestion[:table]}: [#{suggestion[:columns].join(', ')}]"
        else
          puts "  💡 #{suggestion[:table]}: [#{suggestion[:columns].join(', ')}]"
          puts "     Reason: #{suggestion[:reason]}"
        end
      end
    end
    
    puts "\n" + "="*80
    puts "Audit complete!"
    puts "="*80 + "\n"
  end
end

#!/usr/bin/env ruby

# Smart Menu JavaScript Cleanup Script
# This script identifies and helps clean up old JavaScript files that have been replaced by the new modular system

require 'fileutils'
require 'find'

class JavaScriptCleanup
  def initialize
    @app_root = File.expand_path('..', __dir__)
    @js_path = File.join(@app_root, 'app', 'javascript')
    @old_files = []
    @duplicated_code = []
    @backup_dir = File.join(@app_root, 'tmp', 'js_backup')
  end

  def run
    puts '🧹 Smart Menu JavaScript Cleanup'
    puts '================================'
    puts

    analyze_old_files
    identify_duplicated_code
    generate_cleanup_report

    if confirm_cleanup?
      create_backup
      perform_cleanup
      puts '✅ Cleanup completed successfully!'
    else
      puts '❌ Cleanup cancelled'
    end
  end

  private

  def analyze_old_files
    puts '📋 Analyzing old JavaScript files...'

    # Files that have been replaced by the new modular system
    old_patterns = [
      'app/javascript/custom/restaurants.js',
      'app/javascript/custom/menus.js',
      'app/javascript/custom/menu_items.js',
      'app/javascript/custom/employees.js',
      'app/javascript/custom/orders.js',
      'app/javascript/custom/inventories.js',
      'app/javascript/custom/ocr_menu_imports.js',
      'app/javascript/custom/analytics.js',
      'app/javascript/custom/notifications.js',
    ]

    old_patterns.each do |pattern|
      full_path = File.join(@app_root, pattern)
      next unless File.exist?(full_path)

      @old_files << {
        path: full_path,
        relative_path: pattern,
        size: File.size(full_path),
        lines: File.readlines(full_path).count,
      }
    end

    puts "  Found #{@old_files.length} old files to review"
    @old_files.each do |file|
      puts "    - #{file[:relative_path]} (#{file[:lines]} lines, #{file[:size]} bytes)"
    end
    puts
  end

  def identify_duplicated_code
    puts '🔍 Identifying duplicated code patterns...'

    # Common patterns that might be duplicated
    duplication_patterns = [
      {
        name: 'TomSelect initialization',
        pattern: /new\s+TomSelect\s*\(/,
        replacement: 'Centralized in FormManager',
      },
      {
        name: 'Tabulator initialization',
        pattern: /new\s+Tabulator\s*\(/,
        replacement: 'Centralized in TableManager',
      },
      {
        name: 'jQuery document ready',
        pattern: /\$\(document\)\.ready/,
        replacement: 'Turbo:load events in ApplicationManager',
      },
      {
        name: 'Bootstrap tooltip initialization',
        pattern: /new\s+bootstrap\.Tooltip/,
        replacement: 'Centralized Bootstrap initialization',
      },
      {
        name: 'AJAX form submissions',
        pattern: /\$\.ajax\s*\(/,
        replacement: 'Centralized API utilities',
      },
    ]

    @old_files.each do |file|
      content = File.read(file[:path])

      duplication_patterns.each do |pattern|
        matches = content.scan(pattern[:pattern])
        next unless matches.any?

        @duplicated_code << {
          file: file[:relative_path],
          pattern: pattern[:name],
          count: matches.length,
          replacement: pattern[:replacement],
        }
      end
    end

    puts "  Found #{@duplicated_code.length} duplication instances"
    @duplicated_code.each do |dup|
      puts "    - #{dup[:file]}: #{dup[:count]}x #{dup[:pattern]} → #{dup[:replacement]}"
    end
    puts
  end

  def generate_cleanup_report
    puts '📊 Cleanup Report'
    puts '=================='

    total_lines = @old_files.sum { |f| f[:lines] }
    total_size = @old_files.sum { |f| f[:size] }

    puts "Files to remove: #{@old_files.length}"
    puts "Total lines: #{total_lines}"
    puts "Total size: #{(total_size / 1024.0).round(2)} KB"
    puts

    puts "Code duplication instances: #{@duplicated_code.length}"
    puts "Estimated code reduction: ~#{(total_lines * 0.7).round} lines"
    puts

    puts '📁 Files marked for removal:'
    @old_files.each do |file|
      puts "  ❌ #{file[:relative_path]}"
    end
    puts

    puts '🔄 Duplication patterns found:'
    @duplicated_code.group_by { |d| d[:pattern] }.each do |pattern, instances|
      total_count = instances.sum { |i| i[:count] }
      puts "  🔁 #{pattern}: #{total_count} instances across #{instances.length} files"
    end
    puts
  end

  def confirm_cleanup?
    print '❓ Do you want to proceed with cleanup? (y/N): '
    response = $stdin.gets.chomp.downcase
    %w[y yes].include?(response)
  end

  def create_backup
    puts '💾 Creating backup...'

    FileUtils.mkdir_p(@backup_dir)
    timestamp = Time.zone.now.strftime('%Y%m%d_%H%M%S')
    backup_path = File.join(@backup_dir, "js_cleanup_#{timestamp}")
    FileUtils.mkdir_p(backup_path)

    @old_files.each do |file|
      relative_dir = File.dirname(file[:relative_path])
      backup_file_dir = File.join(backup_path, relative_dir)
      FileUtils.mkdir_p(backup_file_dir)

      FileUtils.cp(file[:path], File.join(backup_path, file[:relative_path]))
    end

    puts "  ✅ Backup created at: #{backup_path}"
  end

  def perform_cleanup
    puts '🗑️  Removing old files...'

    @old_files.each do |file|
      if File.exist?(file[:path])
        FileUtils.rm(file[:path])
        puts "  ❌ Removed: #{file[:relative_path]}"
      end
    end

    # Clean up empty directories
    cleanup_empty_directories

    puts '  ✅ Cleanup completed'
  end

  def cleanup_empty_directories
    custom_dir = File.join(@js_path, 'custom')
    return unless Dir.exist?(custom_dir)

    # Remove empty subdirectories
    Dir.glob(File.join(custom_dir, '*')).each do |dir|
      if File.directory?(dir) && Dir.empty?(dir)
        FileUtils.rmdir(dir)
        puts "  📁 Removed empty directory: #{File.basename(dir)}"
      end
    end

    # Remove custom directory if empty
    if Dir.empty?(custom_dir)
      FileUtils.rmdir(custom_dir)
      puts '  📁 Removed empty custom directory'
    end
  end
end

# Run the cleanup if this script is executed directly
if __FILE__ == $PROGRAM_NAME
  cleanup = JavaScriptCleanup.new
  cleanup.run
end

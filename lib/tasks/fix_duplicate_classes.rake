# frozen_string_literal: true

namespace :css do
  desc 'Fix duplicate class attributes in view files'
  task fix_duplicates: :environment do
    puts '🔧 Fixing duplicate class attributes in view files...'

    # Find all ERB view files
    view_files = Rails.root.glob('app/views/**/*.html.erb')

    total_fixes = 0

    view_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup

      # Fix duplicate class attributes like: class="foo" class="bar"
      # Replace with: class="foo bar"
      content.gsub!(/class="([^"]*)" class="([^"]*)"/) do |_match|
        class1 = Regexp.last_match(1).strip
        class2 = Regexp.last_match(2).strip

        # Combine classes, removing duplicates
        combined_classes = (class1.split(/\s+/) + class2.split(/\s+/)).uniq.join(' ')
        "class=\"#{combined_classes}\""
      end

      # Fix cases with single quotes too
      content.gsub!(/class='([^']*)' class='([^']*)'/) do |_match|
        class1 = Regexp.last_match(1).strip
        class2 = Regexp.last_match(2).strip

        # Combine classes, removing duplicates
        combined_classes = (class1.split(/\s+/) + class2.split(/\s+/)).uniq.join(' ')
        "class='#{combined_classes}'"
      end

      # Fix mixed quotes: class="foo" class='bar'
      content.gsub!(/class="([^"]*)" class='([^']*)'/) do |_match|
        class1 = Regexp.last_match(1).strip
        class2 = Regexp.last_match(2).strip

        # Combine classes, removing duplicates
        combined_classes = (class1.split(/\s+/) + class2.split(/\s+/)).uniq.join(' ')
        "class=\"#{combined_classes}\""
      end

      # Fix mixed quotes: class='foo' class="bar"
      content.gsub!(/class='([^']*)' class="([^"]*)"/) do |_match|
        class1 = Regexp.last_match(1).strip
        class2 = Regexp.last_match(2).strip

        # Combine classes, removing duplicates
        combined_classes = (class1.split(/\s+/) + class2.split(/\s+/)).uniq.join(' ')
        "class='#{combined_classes}'"
      end

      next unless content != original_content

      File.write(file_path, content)
      file_fixes = original_content.scan(/class="[^"]*" class="[^"]*"|class='[^']*' class='[^']*'/).count
      puts "  ✅ #{File.basename(file_path)}: #{file_fixes} duplicate class attributes fixed"
      total_fixes += file_fixes
    end

    puts "\n🎉 Duplicate class fix complete!"
    puts "📊 Total files processed: #{view_files.count}"
    puts "🔄 Total duplicate class attributes fixed: #{total_fixes}"
  end
end

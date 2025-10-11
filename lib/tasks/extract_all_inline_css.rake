namespace :css do
  desc 'Extract all remaining inline CSS from view files'
  task extract_all: :environment do
    puts '🔍 Extracting all remaining inline CSS from view files...'

    # Define replacement patterns
    replacements = [
      # Most common patterns first
      ['style="padding-top:10px"', 'class="table-container-spacing"'],
      ['style="padding-top:20px"', 'class="section-spacing-top"'],
      ['style="padding-bottom:10px;box-shadow: 0 4px 2px -2px gray;"', 'class="menu-sticky-header"'],
      ['style="height:43px;overflow-y:hidden;"', 'class="nav-tabs-height"'],
      ['style="position:relative;top:-43px;"', 'class="menu-content-positioned"'],
      ['style="font-size: 3rem;"', 'class="text-large"'],
      ['style="position:relative;top:-5px!important;margin-top:5px"', 'class="position-relative-top-neg5"'],
      ['style="z-index:1070;"', 'class="z-index-high"'],
      ['style="margin-top:5px"', 'class="item-spacing"'],
      ['style="width: 100%;"', 'class="full-width"'],
      ['style="height: 3px;"', 'class="height-3px"'],
      ['style="width: 36px; height: 36px; z-index: 1;"', 'class="icon-size-36"'],
      ['style="width: 34%;"', 'class="w-34"'],
      ['style="width: 22%;"', 'class="w-22"'],
      ['style="padding-bottom:20px"', 'class="section-spacing-bottom"'],
      ['style="padding-top:20px;padding-bottom:20px"', 'class="section-spacing-vertical"'],

      # Text alignment patterns
      ["style='text-align: left;'", 'class="text-align-left"'],
      ['style="text-align: left;"', 'class="text-align-left"'],

      # Position patterns
      ["style='position:relative;right:25px;'", 'class="position-relative-right-25"'],
      ['style="position:relative;right:25px;"', 'class="position-relative-right-25"'],
    ]

    # Find all view files with inline styles
    view_files = Dir.glob('app/views/**/*.html.erb').select do |file|
      File.read(file).include?('style=')
    end

    total_replacements = 0

    view_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup

      replacements.each do |pattern, replacement|
        next unless content.include?(pattern)

        count = content.scan(pattern).length
        content.gsub!(pattern, replacement)
        if count.positive?
          puts "  ✅ #{file_path}: Replaced #{count} instances of #{pattern}"
          total_replacements += count
        end
      end

      # Write back if changes were made
      if content != original_content
        File.write(file_path, content)
      end
    end

    puts "\n📊 EXTRACTION SUMMARY"
    puts '=' * 50
    puts "Total replacements made: #{total_replacements}"

    # Count remaining inline styles
    remaining_count = 0
    view_files.each do |file|
      remaining_count += File.read(file).scan('style=').length
    end

    puts "Remaining inline styles: #{remaining_count}"

    if remaining_count.zero?
      puts '🎉 SUCCESS! All inline styles have been extracted!'
    else
      puts "⚠️  #{remaining_count} inline styles still need manual extraction"

      # Show remaining patterns
      puts "\n🔍 Remaining patterns to extract:"
      remaining_patterns = {}
      view_files.each do |file|
        content = File.read(file)
        content.scan(/style="([^"]*)"/).each do |match|
          pattern = match[0]
          remaining_patterns[pattern] = (remaining_patterns[pattern] || 0) + 1
        end
        content.scan(/style='([^']*)'/).each do |match|
          pattern = match[0]
          remaining_patterns[pattern] = (remaining_patterns[pattern] || 0) + 1
        end
      end

      remaining_patterns.sort_by { |_k, v| -v }.first(10).each do |pattern, count|
        puts "  #{count}x: #{pattern}"
      end
    end
  end
end

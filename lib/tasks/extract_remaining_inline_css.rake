namespace :css do
  desc "Extract remaining specific inline CSS patterns"
  task :extract_remaining => :environment do
    puts "🔍 Extracting remaining specific inline CSS patterns..."
    
    # Define remaining replacement patterns
    replacements = [
      # Complex navigation patterns (these need to be handled differently)
      # We'll skip the complex gradient ones for now and handle them manually
      
      # Text and spacing patterns
      ['style="text-align:justify;"', 'class="text-justify"'],
      ['style="padding-left: 5px;"', 'class="padding-left-sm"'],
      ['style="padding-left:10px;padding-right:10px;text-align:center;"', 'class="text-center-padded"'],
      ['style="text-align: left;padding-left: 5px;"', 'class="text-left-padded"'],
      ['style="padding-top:5px"', 'class="padding-top-xs"'],
      ['style="max-width: 180px;"', 'class="max-width-180"'],
      ['style="font-size: 4rem;"', 'class="text-extra-large"'],
      ['style="top: 2rem;"', 'class="top-2rem"'],
      ['style="max-width: 1200px;"', 'class="max-width-1200"'],
      
      # Handle variations with single quotes
      ["style='text-align:justify;'", 'class="text-justify"'],
      ["style='padding-left: 5px;'", 'class="padding-left-sm"'],
      ["style='padding-left:10px;padding-right:10px;text-align:center;'", 'class="text-center-padded"'],
      ["style='text-align: left;padding-left: 5px;'", 'class="text-left-padded"'],
      ["style='padding-top:5px'", 'class="padding-top-xs"'],
      ["style='max-width: 180px;'", 'class="max-width-180"'],
      ["style='font-size: 4rem;'", 'class="text-extra-large"'],
      ["style='top: 2rem;'", 'class="top-2rem"'],
      ["style='max-width: 1200px;'", 'class="max-width-1200"'],
    ]
    
    # Find all view files with inline styles
    view_files = Dir.glob("app/views/**/*.html.erb").select do |file|
      File.read(file).include?('style=')
    end
    
    total_replacements = 0
    
    view_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup
      
      replacements.each do |pattern, replacement|
        if content.include?(pattern)
          count = content.scan(pattern).length
          content.gsub!(pattern, replacement)
          if count > 0
            puts "  ✅ #{file_path}: Replaced #{count} instances of #{pattern}"
            total_replacements += count
          end
        end
      end
      
      # Write back if changes were made
      if content != original_content
        File.write(file_path, content)
      end
    end
    
    puts "\n📊 EXTRACTION SUMMARY"
    puts "=" * 50
    puts "Total replacements made: #{total_replacements}"
    
    # Count remaining inline styles
    remaining_count = 0
    view_files.each do |file|
      remaining_count += File.read(file).scan(/style=/).length
    end
    
    puts "Remaining inline styles: #{remaining_count}"
    
    if remaining_count == 0
      puts "🎉 SUCCESS! All inline styles have been extracted!"
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
      
      remaining_patterns.sort_by { |k, v| -v }.each do |pattern, count|
        puts "  #{count}x: #{pattern}"
      end
      
      # Show which files still have inline styles
      puts "\n📁 Files with remaining inline styles:"
      view_files.each do |file|
        count = File.read(file).scan(/style=/).length
        if count > 0
          puts "  #{file}: #{count} inline styles"
        end
      end
    end
  end
end

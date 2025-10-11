namespace :css do
  desc 'Extract final batch of inline CSS patterns'
  task extract_final: :environment do
    puts '🔍 Extracting final batch of inline CSS patterns...'

    # Define final replacement patterns (excluding dynamic ones)
    replacements = [
      # Static patterns only
      ['style="height:90vh;overflow:scroll "', 'class="height-90vh-scroll"'],
      ['style="padding-bottom:5px;"', 'class="padding-bottom-xs"'],
      ['style="padding-top:50px;padding-bottom:50px;display:flex;justify-content: center;align-items: center;"',
       'class="hero-section"',],
      ['style="padding-top:7px"', 'class="padding-top-7px"'],
      ['style="padding:1px;display:inline-block;"', 'class="inline-block-padded"'],
      ['style="max-height:40px"', 'class="max-height-40"'],
      ['style="min-height:60px;"', 'class="min-height-60"'],
      ['style="padding-top:2px;padding-bottom:5px;width:100%;height:200px;"', 'class="form-textarea-custom"'],
      ['style="height: 8px;"', 'class="progress-bar-8"'],
      ['style="height: 200px; border-radius: 8px;"', 'class="qr-placeholder"'],
      ['style="font-size: 2rem;"', 'class="text-2rem"'],
      ['style="height: 10px;"', 'class="progress-bar-10"'],
      ['style="flex: 1;"', 'class="flex-1"'],
      ['style="max-width: 60%;"', 'class="max-width-60"'],
      ['style="position:relative;top:5px!important;margin-top:5px"', 'class="position-relative-top5"'],
      ['style="height: 150px"', 'class="height-150"'],
      ['style="position:relative; left:-37px"', 'class="position-relative-left-neg37"'],
      ['style="position:relative; left:-10px"', 'class="position-relative-left-neg10"'],
      ['style="height:40px"', 'class="height-40"'],
      ['style="top:-7px"', 'class="top-neg7"'],
      ['style="text-align:center;"', 'class="text-center"'],
      ['style="padding-left: 0;padding-right: 0;"', 'class="padding-horizontal-0"'],

      # Handle variations with single quotes
      ["style='height:90vh;overflow:scroll '", 'class="height-90vh-scroll"'],
      ["style='padding-bottom:5px;'", 'class="padding-bottom-xs"'],
      ["style='padding-top:50px;padding-bottom:50px;display:flex;justify-content: center;align-items: center;'",
       'class="hero-section"',],
      ["style='padding-top:7px'", 'class="padding-top-7px"'],
      ["style='padding:1px;display:inline-block;'", 'class="inline-block-padded"'],
      ["style='max-height:40px'", 'class="max-height-40"'],
      ["style='min-height:60px;'", 'class="min-height-60"'],
      ["style='padding-top:2px;padding-bottom:5px;width:100%;height:200px;'", 'class="form-textarea-custom"'],
      ["style='height: 8px;'", 'class="progress-bar-8"'],
      ["style='height: 200px; border-radius: 8px;'", 'class="qr-placeholder"'],
      ["style='font-size: 2rem;'", 'class="text-2rem"'],
      ["style='height: 10px;'", 'class="progress-bar-10"'],
      ["style='flex: 1;'", 'class="flex-1"'],
      ["style='max-width: 60%;'", 'class="max-width-60"'],
      ["style='position:relative;top:5px!important;margin-top:5px'", 'class="position-relative-top5"'],
      ["style='height: 150px'", 'class="height-150"'],
      ["style='position:relative; left:-37px'", 'class="position-relative-left-neg37"'],
      ["style='position:relative; left:-10px'", 'class="position-relative-left-neg10"'],
      ["style='height:40px'", 'class="height-40"'],
      ["style='top:-7px'", 'class="top-neg7"'],
      ["style='text-align:center;'", 'class="text-center"'],
      ["style='padding-left: 0;padding-right: 0;'", 'class="padding-horizontal-0"'],
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

    puts "\n📊 FINAL EXTRACTION SUMMARY"
    puts '=' * 50
    puts "Total replacements made: #{total_replacements}"

    # Count remaining inline styles
    remaining_count = 0
    dynamic_patterns = []

    view_files.each do |file|
      content = File.read(file)
      remaining_count += content.scan('style=').length

      # Collect dynamic patterns (containing ERB)
      content.scan(/style="([^"]*<%[^>]*%>[^"]*)"/).each do |match|
        dynamic_patterns << match[0]
      end
      content.scan(/style='([^']*<%[^>]*%>[^']*)'/).each do |match|
        dynamic_patterns << match[0]
      end
    end

    puts "Remaining inline styles: #{remaining_count}"

    if remaining_count.zero?
      puts '🎉 SUCCESS! All inline styles have been extracted!'
    else
      puts "⚠️  #{remaining_count} inline styles still remain"

      # Show remaining patterns
      puts "\n🔍 Remaining patterns:"
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

      remaining_patterns.sort_by { |_k, v| -v }.each do |pattern, count|
        if pattern.include?('<%')
          puts "  #{count}x: #{pattern} (DYNAMIC - contains ERB)"
        else
          puts "  #{count}x: #{pattern}"
        end
      end

      puts "\n📝 Note: Dynamic patterns containing ERB (<%...%>) cannot be extracted to CSS classes"
      puts '    and may need to remain as inline styles or be handled with CSS custom properties.'
    end
  end
end

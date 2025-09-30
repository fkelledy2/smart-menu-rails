namespace :css do
  desc "Fix all remaining duplicate class attributes"
  task :fix_all_duplicates => :environment do
    puts "🔍 Finding and fixing all duplicate class attributes..."
    
    # Find all view files
    view_files = Dir.glob("app/views/**/*.html.erb")
    
    total_fixes = 0
    
    view_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup
      
      # Fix duplicate class attributes using regex
      # Pattern: class="something" class="something else"
      # Replace with: class="something something else"
      content.gsub!(/class="([^"]*)" class="([^"]*)"/) do |match|
        class1 = $1.strip
        class2 = $2.strip
        combined_classes = "#{class1} #{class2}".strip
        "class=\"#{combined_classes}\""
      end
      
      # Also handle cases with single quotes
      content.gsub!(/class='([^']*)' class='([^']*)'/) do |match|
        class1 = $1.strip
        class2 = $2.strip
        combined_classes = "#{class1} #{class2}".strip
        "class='#{combined_classes}'"
      end
      
      # Handle mixed quotes
      content.gsub!(/class="([^"]*)" class='([^']*)'/) do |match|
        class1 = $1.strip
        class2 = $2.strip
        combined_classes = "#{class1} #{class2}".strip
        "class=\"#{combined_classes}\""
      end
      
      content.gsub!(/class='([^']*)' class="([^"]*)"/) do |match|
        class1 = $1.strip
        class2 = $2.strip
        combined_classes = "#{class1} #{class2}".strip
        "class='#{combined_classes}'"
      end
      
      # Write back if changes were made
      if content != original_content
        File.write(file_path, content)
        fixes_count = original_content.scan(/class="[^"]*" class=/).length + 
                     original_content.scan(/class='[^']*' class=/).length
        puts "  ✅ #{file_path}: Fixed #{fixes_count} duplicate class attributes"
        total_fixes += fixes_count
      end
    end
    
    puts "\n📊 DUPLICATE CLASS FIX SUMMARY"
    puts "=" * 50
    puts "Total duplicate class attributes fixed: #{total_fixes}"
    
    # Verify no duplicates remain
    remaining_duplicates = 0
    view_files.each do |file|
      content = File.read(file)
      remaining_duplicates += content.scan(/class="[^"]*" class=/).length
      remaining_duplicates += content.scan(/class='[^']*' class=/).length
    end
    
    if remaining_duplicates == 0
      puts "🎉 SUCCESS! All duplicate class attributes have been fixed!"
    else
      puts "⚠️  #{remaining_duplicates} duplicate class attributes still remain"
    end
  end
end

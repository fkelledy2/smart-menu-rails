# frozen_string_literal: true

namespace :css do
  desc "Verify CSS extraction and compilation is working correctly"
  task verify: :environment do
    puts "🔍 Verifying CSS extraction and compilation..."
    
    # 1. Check for remaining duplicate class attributes
    puts "\n1. Checking for duplicate class attributes..."
    duplicate_count = 0
    Dir.glob(Rails.root.join('app', 'views', '**', '*.html.erb')).each do |file|
      content = File.read(file)
      duplicates = content.scan(/class="[^"]*" class="[^"]*"|class='[^']*' class='[^']*'/).count
      if duplicates > 0
        puts "  ❌ #{File.basename(file)}: #{duplicates} duplicate class attributes"
        duplicate_count += duplicates
      end
    end
    
    if duplicate_count == 0
      puts "  ✅ No duplicate class attributes found"
    else
      puts "  ❌ Found #{duplicate_count} duplicate class attributes"
    end
    
    # 2. Check if CSS files exist
    puts "\n2. Checking CSS file structure..."
    css_files = [
      'app/assets/stylesheets/application.bootstrap.scss',
      'app/assets/stylesheets/components/_forms.scss',
      'app/assets/stylesheets/components/_navigation.scss',
      'app/assets/stylesheets/components/_tables.scss',
      'app/assets/stylesheets/components/_scrollbars.scss',
      'app/assets/stylesheets/components/_utilities.scss',
      'app/assets/stylesheets/pages/_home.scss',
      'app/assets/stylesheets/pages/_onboarding.scss',
      'app/assets/stylesheets/pages/_smartmenu.scss',
      'app/assets/stylesheets/themes/_variables.scss',
      'app/assets/stylesheets/themes/_component-overrides.scss'
    ]
    
    missing_files = []
    css_files.each do |file|
      if File.exist?(Rails.root.join(file))
        puts "  ✅ #{file}"
      else
        puts "  ❌ #{file} - MISSING"
        missing_files << file
      end
    end
    
    # 3. Check if CSS compiles without errors
    puts "\n3. Testing CSS compilation..."
    begin
      result = `cd #{Rails.root} && yarn build:css 2>&1`
      if $?.success?
        puts "  ✅ CSS compilation successful"
      else
        puts "  ❌ CSS compilation failed:"
        puts result.lines.last(5).join
      end
    rescue => e
      puts "  ❌ CSS compilation error: #{e.message}"
    end
    
    # 4. Check if compiled CSS contains our custom classes
    puts "\n4. Checking compiled CSS for custom classes..."
    compiled_css_path = Rails.root.join('app/assets/builds/application.css')
    
    if File.exist?(compiled_css_path)
      compiled_css = File.read(compiled_css_path)
      
      test_classes = [
        '.spacing-sm',
        '.feature-card',
        '.hero-caption',
        '.nav-tabs-fixed-height',
        '.menu-section-spacing',
        '.table-container'
      ]
      
      missing_classes = []
      test_classes.each do |css_class|
        if compiled_css.include?(css_class)
          puts "  ✅ #{css_class} found in compiled CSS"
        else
          puts "  ❌ #{css_class} missing from compiled CSS"
          missing_classes << css_class
        end
      end
      
      if missing_classes.empty?
        puts "  ✅ All custom CSS classes found in compiled CSS"
      else
        puts "  ❌ #{missing_classes.count} custom classes missing from compiled CSS"
      end
    else
      puts "  ❌ Compiled CSS file not found at #{compiled_css_path}"
    end
    
    # 5. Summary
    puts "\n" + "="*60
    puts "📊 VERIFICATION SUMMARY"
    puts "="*60
    
    if duplicate_count == 0 && missing_files.empty?
      puts "✅ CSS extraction and setup is working correctly!"
      puts "🎨 Your application is ready for Bootstrap theme integration"
      puts "\n🚀 Next steps:"
      puts "  1. Choose a Bootstrap theme or customize variables"
      puts "  2. Update themes/_variables.scss with your brand colors"
      puts "  3. Test the application in your browser"
    else
      puts "❌ Issues found that need to be resolved:"
      puts "  - Duplicate class attributes: #{duplicate_count}" if duplicate_count > 0
      puts "  - Missing CSS files: #{missing_files.count}" if missing_files.any?
      puts "\n🔧 Run the following commands to fix issues:"
      puts "  bundle exec rails css:fix_duplicates" if duplicate_count > 0
    end
  end
end

# frozen_string_literal: true

require 'English'
namespace :css do
  desc 'Verify CSS extraction and Bootstrap theme setup is working correctly'
  task verify: :environment do
    puts '🔍 Verifying CSS extraction and Bootstrap theme setup...'

    # 1. Check CSS file structure
    puts "\n1. Checking CSS file structure..."
    required_files = [
      'app/assets/stylesheets/application.bootstrap.scss',
      'app/assets/stylesheets/components/_utilities.scss',
      'app/assets/stylesheets/components/_forms.scss',
      'app/assets/stylesheets/components/_navigation.scss',
      'app/assets/stylesheets/components/_tables.scss',
      'app/assets/stylesheets/components/_scrollbars.scss',
      'app/assets/stylesheets/pages/_home.scss',
      'app/assets/stylesheets/pages/_onboarding.scss',
      'app/assets/stylesheets/pages/_smartmenu.scss',
      'app/assets/stylesheets/themes/_variables.scss',
      'app/assets/stylesheets/themes/_component-overrides.scss',
    ]

    missing_files = []
    required_files.each do |file|
      if Rails.root.join(file).exist?
        puts "  ✅ #{file}"
      else
        puts "  ❌ #{file} - MISSING"
        missing_files << file
      end
    end

    # 2. Check CSS compilation
    puts "\n2. Testing CSS compilation..."
    begin
      result = `cd #{Rails.root} && yarn build:css 2>&1`
      if $CHILD_STATUS.success?
        puts '  ✅ CSS compilation successful'
      else
        puts '  ❌ CSS compilation failed:'
        puts result.lines.last(5).join
      end
    rescue StandardError => e
      puts "  ❌ CSS compilation error: #{e.message}"
    end

    # 3. Check if compiled CSS contains utility classes
    puts "\n3. Checking compiled CSS for utility classes..."
    compiled_css_path = Rails.root.join('app', 'assets', 'builds', 'application.css', 'application.css', 'builds', 'application.css',
                                        'application.css',)

    if File.exist?(compiled_css_path)
      compiled_css = File.read(compiled_css_path)

      test_classes = [
        '.spacing-sm',
        '.spacing-md',
        '.padding-top-md',
        '.display-none',
        '.nav-tabs-fixed-height',
        '.table-container',
        '.feature-card',
        '.feature-icon',
        '.hero-carousel',
        '.hero-overlay',
        '.wizard-form',
        '.qr-code-placeholder',
        '.progress-custom',
      ]

      missing_classes = []
      found_classes = []

      test_classes.each do |css_class|
        if compiled_css.include?(css_class)
          puts "  ✅ #{css_class}"
          found_classes << css_class
        else
          puts "  ❌ #{css_class} - MISSING"
          missing_classes << css_class
        end
      end

      puts "\n  📊 Found #{found_classes.count}/#{test_classes.count} utility classes"
    else
      puts "  ❌ Compiled CSS file not found at #{compiled_css_path}"
    end

    # 4. Check remaining inline styles
    puts "\n4. Checking remaining inline styles..."
    view_files = Rails.root.glob('app/views/**/*.html.erb')
    remaining_count = 0

    view_files.each do |file|
      content = File.read(file)
      content.each_line do |line|
        remaining_count += 1 if /style\s*=\s*['"][^'"]*['"]/.match?(line)
      end
    end

    puts "  📊 Remaining inline styles: #{remaining_count}"
    if remaining_count < 250
      puts '  ✅ Good! Most inline styles have been extracted'
    else
      puts '  ⚠️  Consider running additional extraction tasks'
    end

    # 5. Check Bootstrap theme integration
    puts "\n5. Checking Bootstrap theme integration..."
    app_scss = Rails.root.join('app', 'assets', 'stylesheets', 'application.bootstrap.scss', 'application.bootstrap.scss',
                               'stylesheets', 'application.bootstrap.scss', 'application.bootstrap.scss',)

    if File.exist?(app_scss)
      content = File.read(app_scss)

      checks = [
        ['themes/variables', 'Theme variables import'],
        ['bootstrap/scss/bootstrap', 'Bootstrap core import'],
        ['themes/component-overrides', 'Theme overrides import'],
        ['components/utilities', 'Utilities import'],
        ['pages/home', 'Home page styles import'],
      ]

      checks.each do |import, description|
        if content.include?("@import \"#{import}\"")
          puts "  ✅ #{description}"
        else
          puts "  ❌ #{description} - MISSING"
        end
      end
    else
      puts '  ❌ Main SCSS file not found'
    end

    # 6. Summary and recommendations
    puts "\n#{'=' * 60}"
    puts '📊 VERIFICATION SUMMARY'
    puts '=' * 60

    total_issues = missing_files.count + (missing_classes&.count || 0)

    if total_issues.zero? && remaining_count < 250
      puts '✅ CSS extraction and Bootstrap theme setup is working perfectly!'
      puts '🎨 Your application is ready for Bootstrap theme integration'
      puts "\n🚀 Next steps:"
      puts '  1. Choose a Bootstrap theme or customize variables in themes/_variables.scss'
      puts '  2. Update brand colors: $primary, $secondary, etc.'
      puts '  3. Test the application in your browser'
      puts '  4. Apply component overrides in themes/_component-overrides.scss'

    elsif total_issues < 5
      puts '⚠️  Minor issues found, but setup is mostly working:'
      puts "  - Missing files: #{missing_files.count}" if missing_files.any?
      puts "  - Missing CSS classes: #{missing_classes&.count || 0}" if missing_classes&.any?
      puts "  - Remaining inline styles: #{remaining_count}"
      puts "\n🔧 Recommended actions:"
      puts '  1. Run: yarn build:css'
      puts '  2. Check for any SCSS syntax errors'
      puts '  3. Verify all imports in application.bootstrap.scss'

    else
      puts '❌ Significant issues found that need attention:'
      puts "  - Missing files: #{missing_files.count}" if missing_files.any?
      puts "  - Missing CSS classes: #{missing_classes&.count || 0}" if missing_classes&.any?
      puts "  - Remaining inline styles: #{remaining_count}"
      puts "\n🔧 Required actions:"
      puts '  1. Ensure all SCSS files are created'
      puts '  2. Fix CSS compilation errors'
      puts '  3. Run additional extraction tasks'
      puts '  4. Verify application.bootstrap.scss imports'
    end

    puts "\n📋 Available commands:"
    puts '  bundle exec rails css:extract           # Extract inline CSS'
    puts '  bundle exec rails css:extract_remaining # Extract additional patterns'
    puts '  bundle exec rails css:find_remaining    # Find remaining inline styles'
    puts '  yarn build:css                         # Compile CSS'
    puts '  bundle exec rails css:verify           # Run this verification again'
  end
end

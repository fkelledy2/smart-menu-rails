# frozen_string_literal: true

namespace :css do
  desc "Extract inline CSS from view files and replace with CSS classes"
  task extract: :environment do
    puts "🎨 Extracting inline CSS from view files..."
    
    # Define common inline style replacements based on analysis
    replacements = {
      # Height spacers (most common: 128 occurrences)
      'style=\'height:4px\'' => 'class="spacing-sm"',
      'style="height:4px"' => 'class="spacing-sm"',
      'style=\'height:8px\'' => 'class="spacing-md"',
      'style="height:8px"' => 'class="spacing-md"',
      'style=\'height:5px\'' => 'class="spacing-xs"',
      'style="height:5px"' => 'class="spacing-xs"',
      
      # Padding utilities (34 occurrences)
      'style=\'padding-left:15px;\'' => 'class="padding-left-md"',
      'style="padding-left:15px;"' => 'class="padding-left-md"',
      
      # Display utilities
      'style=\'display:none\'' => 'class="display-none"',
      'style="display:none"' => 'class="display-none"',
      'style=\'display:none;\'' => 'class="display-none"',
      'style="display:none;"' => 'class="display-none"',
      
      # Navigation specific (23 occurrences)
      'style="height:43px;overflow-y:hidden;"' => 'class="nav-tabs-fixed-height"',
      'style=\'height:43px;overflow-y:hidden;\'' => 'class="nav-tabs-fixed-height"',
      'style="position:relative;top:-43px;"' => 'class="tab-content-offset"',
      'style=\'position:relative;top:-43px;\'' => 'class="tab-content-offset"',
      
      # Complex navigation with gradient
      'style="position:relative;top:-43px;left:50px;height:43px;overflow-y:hidden;width:85%;mask-image: linear-gradient(to right, #008080, rgba(0,32,32,0) 120%"' => 'class="nav-tabs-scrollable"',
      'style=\'position:relative;top:-43px;left:50px;height:43px;overflow-y:hidden;width:85%;mask-image: linear-gradient(to right, #008080, rgba(0,32,32,0) 120%\'' => 'class="nav-tabs-scrollable"',
      
      # Sticky navigation
      'style="padding-bottom:10px;box-shadow: 0 4px 2px -2px gray;"' => 'class="sticky-nav"',
      'style=\'padding-bottom:10px;box-shadow: 0 4px 2px -2px gray;\'' => 'class="sticky-nav"',
      
      # Colors (9 occurrences)
      'style="color:green;"' => 'class="feature-icon"',
      'style=\'color:green;\'' => 'class="feature-icon"',
      
      # Z-index utilities
      'style="z-index:1070;"' => 'class="z-index-dropdown"',
      'style=\'z-index:1070;\'' => 'class="z-index-dropdown"',
      'style="z-index:+10000;"' => 'class="z-index-10000"',
      'style=\'z-index:+10000;\'' => 'class="z-index-10000"',
      
      # Width utilities
      'style="width:100%"' => 'class="width-full"',
      'style=\'width:100%\'' => 'class="width-full"',
      'style="width: 100%;"' => 'class="width-full"',
      'style=\'width: 100%;\'' => 'class="width-full"',
      
      # Text alignment
      'style=\'text-align: left;\'' => 'class="text-left-force"',
      'style="text-align: left;"' => 'class="text-left-force"',
      
      # Form positioning
      'style="position:relative;top:-5px!important;margin-top:5px"' => 'class="form-icon-position-alt"',
      'style=\'position:relative;top:-5px!important;margin-top:5px\'' => 'class="form-icon-position-alt"',
      'style="position:relative;top:5px!important;margin-top:5px"' => 'class="form-icon-position"',
      'style=\'position:relative;top:5px!important;margin-top:5px\'' => 'class="form-icon-position"',
      
      # Hero section styles
      'style="top:0;left:0;background:rgba(0,0,0,0.32);z-index:1;pointer-events:none;"' => 'class="hero-overlay"',
      'style=\'top:0;left:0;background:rgba(0,0,0,0.32);z-index:1;pointer-events:none;\'' => 'class="hero-overlay"',
      'style=\'left:5%;right:5%;\'' => 'class="hero-caption"',
      'style="left:5%;right:5%;"' => 'class="hero-caption"',
      
      # Carousel styles
      'style="overflow-x: hidden;width: calc(100% + 50px);margin-left: -25px;margin-right: -25px; background: url(\'<%= asset_path(\'table-setting.png\') %>\') no-repeat center center;background-size: cover;"' => 'class="hero-carousel"',
      
      # Feature card styles
      'style=\'padding-right:10px;min-height:120px;text-align:justify\'' => 'class="feature-description"',
      'style="padding-right:10px;min-height:120px;text-align:justify"' => 'class="feature-description"',
      
      # Table container
      'style="padding-top:10px"' => 'class="table-container"',
      'style=\'padding-top:10px\'' => 'class="table-container"',
      
      # Additional common patterns from remaining styles
      'style=\'padding-left:15px;\' class="col d-flex align-items-start feature-card"' => 'class="col d-flex align-items-start feature-card padding-left-md"',
      
      # Font sizes
      'style="font-size: 3rem;"' => 'class="display-4"',
      'style=\'font-size: 3rem;\'' => 'class="display-4"',
      
      # Onboarding specific
      'style="max-width: 1200px;"' => 'class="wizard-form"',
      'style=\'max-width: 1200px;\'' => 'class="wizard-form"',
      'style="height: 8px;"' => 'class="progress-custom"',
      'style=\'height: 8px;\'' => 'class="progress-custom"',
      'style="height: 200px; border-radius: 8px;"' => 'class="qr-code-placeholder"',
      'style=\'height: 200px; border-radius: 8px;\'' => 'class="qr-code-placeholder"',
      'style="max-width: 180px;"' => 'class="qr-code-image"',
      'style=\'max-width: 180px;\'' => 'class="qr-code-image"',
      'style="top: 2rem;"' => 'class="menu-preview"',
      'style=\'top: 2rem;\'' => 'class="menu-preview"',
    }
    
    # Find all ERB view files
    view_files = Dir.glob(Rails.root.join('app', 'views', '**', '*.html.erb'))
    
    total_replacements = 0
    
    view_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup
      file_replacements = 0
      
      # Apply replacements
      replacements.each do |inline_style, css_class|
        count = content.scan(Regexp.escape(inline_style)).length
        if count > 0
          content.gsub!(inline_style, css_class)
          file_replacements += count
        end
      end
      
      # Write back if changes were made
      if content != original_content
        File.write(file_path, content)
        puts "  ✅ #{File.basename(file_path)}: #{file_replacements} replacements"
        total_replacements += file_replacements
      end
    end
    
    puts "\n🎉 Extraction complete!"
    puts "📊 Total files processed: #{view_files.count}"
    puts "🔄 Total replacements made: #{total_replacements}"
    
    puts "\n📝 Next steps:"
    puts "  1. Review the changes in your views"
    puts "  2. Test the application to ensure styles are working"
    puts "  3. Add any custom Bootstrap theme on top of the organized CSS"
  end
  
  desc "Find remaining inline styles in view files"
  task find_remaining: :environment do
    puts "🔍 Finding remaining inline styles..."
    
    view_files = Dir.glob(Rails.root.join('app', 'views', '**', '*.html.erb'))
    remaining_styles = []
    
    view_files.each do |file_path|
      content = File.read(file_path)
      relative_path = file_path.gsub(Rails.root.to_s + '/', '')
      
      content.each_line.with_index(1) do |line, line_number|
        if line.match(/style\s*=\s*['"][^'"]*['"]/)
          remaining_styles << "#{relative_path}:#{line_number} - #{line.strip}"
        end
      end
    end
    
    if remaining_styles.empty?
      puts "✅ No remaining inline styles found!"
    else
      puts "📊 Found #{remaining_styles.count} remaining inline styles:"
      remaining_styles.each { |style| puts style }
    end
  end
end

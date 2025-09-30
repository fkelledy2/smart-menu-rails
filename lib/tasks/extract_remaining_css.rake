# frozen_string_literal: true

namespace :css do
  desc "Extract remaining inline CSS patterns from view files"
  task extract_remaining: :environment do
    puts "🎨 Extracting remaining inline CSS patterns..."
    
    # Additional replacements for remaining patterns
    additional_replacements = {
      # Navigation tabs that weren't caught
      'style="height:43px;overflow-y:hidden;"' => 'class="nav-tabs-fixed-height"',
      'style=\'height:43px;overflow-y:hidden;\'' => 'class="nav-tabs-fixed-height"',
      
      # Table containers that weren't caught  
      'style="padding-top:10px" class="table-borderless"' => 'class="table-container table-borderless"',
      'style=\'padding-top:10px\' class="table-borderless"' => 'class="table-container table-borderless"',
      
      # Hero overlay styles
      'style="top:0;left:0;background:rgba(0,0,0,0.32);z-index:1;pointer-events:none;"' => 'class="hero-overlay"',
      'style=\'top:0;left:0;background:rgba(0,0,0,0.32);z-index:1;pointer-events:none;\'' => 'class="hero-overlay"',
      
      # Hero caption positioning
      'style=\'left:5%;right:5%;\' class="carousel-caption text-start"' => 'class="carousel-caption text-start hero-caption"',
      'style="left:5%;right:5%;" class="carousel-caption text-start"' => 'class="carousel-caption text-start hero-caption"',
      
      # Feature card padding
      'style=\'padding-left:15px;\' class="col d-flex align-items-start feature-card"' => 'class="col d-flex align-items-start feature-card padding-left-md"',
      'style="padding-left:15px;" class="col d-flex align-items-start feature-card"' => 'class="col d-flex align-items-start feature-card padding-left-md"',
      
      # Feature descriptions
      'style=\'padding-right:10px;min-height:120px;text-align:justify\'' => 'class="feature-description"',
      'style="padding-right:10px;min-height:120px;text-align:justify"' => 'class="feature-description"',
      
      # Green color for icons and metrics
      'style=\'color:green;\'' => 'class="feature-icon"',
      'style="color:green;"' => 'class="feature-icon"',
      
      # Display none variations
      'style=\'display:none\' id=' => 'class="display-none" id=',
      'style="display:none" id=' => 'class="display-none" id=',
      'style=\'display:none\' class=' => 'class="display-none" class=',
      'style="display:none" class=' => 'class="display-none" class=',
      
      # Z-index variations
      'style="z-index:+10000;"' => 'class="z-index-10000"',
      'style=\'z-index:+10000;\'' => 'class="z-index-10000"',
      
      # Font sizes
      'style="font-size: 3rem;"' => 'class="fs-1"',
      'style=\'font-size: 3rem;\'' => 'class="fs-1"',
      'style="font-size: 4rem;"' => 'class="display-1"',
      'style=\'font-size: 4rem;\'' => 'class="display-1"',
      
      # Progress bar heights
      'style="height: 8px;"' => 'class="progress-custom"',
      'style=\'height: 8px;\'' => 'class="progress-custom"',
      'style="height: 3px;"' => 'class="progress-thin"',
      'style=\'height: 3px;\'' => 'class="progress-thin"',
      'style="height: 10px;"' => 'class="progress-thick"',
      'style=\'height: 10px;\'' => 'class="progress-thick"',
      
      # Image and media sizes
      'style="max-width: 180px;"' => 'class="qr-code-image"',
      'style=\'max-width: 180px;\'' => 'class="qr-code-image"',
      'style="max-width: 60%;"' => 'class="w-60"',
      'style=\'max-width: 60%;\'' => 'class="w-60"',
      'style="height: 150px"' => 'class="menu-item-image"',
      'style=\'height: 150px\'' => 'class="menu-item-image"',
      
      # Positioning
      'style="top: 2rem;"' => 'class="sticky-offset"',
      'style=\'top: 2rem;\'' => 'class="sticky-offset"',
      'style="position:relative;top:5px!important;margin-top:5px"' => 'class="form-icon-position"',
      'style=\'position:relative;top:5px!important;margin-top:5px\'' => 'class="form-icon-position"',
      'style="position:relative;top:-5px!important;margin-top:5px"' => 'class="form-icon-position-alt"',
      'style=\'position:relative;top:-5px!important;margin-top:5px\'' => 'class="form-icon-position-alt"',
      
      # Width utilities
      'style="width: 100%;"' => 'class="w-100"',
      'style=\'width: 100%;\'' => 'class="w-100"',
      'style="width:100%"' => 'class="w-100"',
      'style=\'width:100%\'' => 'class="w-100"',
      
      # Margin utilities
      'style="margin-top:5px"' => 'class="mt-1"',
      'style=\'margin-top:5px\'' => 'class="mt-1"',
      'style="margin:5px"' => 'class="m-1"',
      'style=\'margin:5px\'' => 'class="m-1"',
      
      # Text alignment
      'style=\'text-align: left;\'' => 'class="text-start"',
      'style="text-align: left;"' => 'class="text-start"',
      'style="text-align:justify"' => 'class="text-justify"',
      'style=\'text-align:justify\'' => 'class="text-justify"',
      
      # Padding variations
      'style="padding:0px!important;"' => 'class="p-0"',
      'style=\'padding:0px!important;\'' => 'class="p-0"',
      'style="padding:40px"' => 'class="p-5"',
      'style=\'padding:40px\'' => 'class="p-5"',
      'style="padding-top:7px"' => 'class="pt-2"',
      'style=\'padding-top:7px\'' => 'class="pt-2"',
      'style="padding-top:5px"' => 'class="pt-1"',
      'style=\'padding-top:5px\'' => 'class="pt-1"',
      'style="padding-top:20px"' => 'class="pt-4"',
      'style=\'padding-top:20px\'' => 'class="pt-4"',
      'style="padding-bottom:20px"' => 'class="pb-4"',
      'style=\'padding-bottom:20px\'' => 'class="pb-4"',
      
      # Onboarding wizard
      'style="max-width: 1200px;"' => 'class="wizard-form"',
      'style=\'max-width: 1200px;\'' => 'class="wizard-form"',
      
      # QR code placeholder
      'style="height: 200px; border-radius: 8px;"' => 'class="qr-code-placeholder"',
      'style=\'height: 200px; border-radius: 8px;\'' => 'class="qr-code-placeholder"',
    }
    
    # Find all ERB view files
    view_files = Dir.glob(Rails.root.join('app', 'views', '**', '*.html.erb'))
    
    total_replacements = 0
    
    view_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup
      file_replacements = 0
      
      # Apply additional replacements
      additional_replacements.each do |inline_style, css_class|
        count = content.scan(Regexp.escape(inline_style)).length
        if count > 0
          content.gsub!(inline_style, css_class)
          file_replacements += count
        end
      end
      
      # Write back if changes were made
      if content != original_content
        File.write(file_path, content)
        puts "  ✅ #{File.basename(file_path)}: #{file_replacements} additional replacements"
        total_replacements += file_replacements
      end
    end
    
    puts "\n🎉 Additional extraction complete!"
    puts "📊 Total files processed: #{view_files.count}"
    puts "🔄 Total additional replacements made: #{total_replacements}"
  end
end

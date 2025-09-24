namespace :menuitems do
  desc "Iterate through all menu items and save them (useful for triggering callbacks)"
  task reprocess: :environment do
    puts "Starting to process all menu items..."
    
    total = Menuitem.count
    success_count = 0
    error_count = 0
    
    Menuitem.find_each.with_index do |menuitem, index|
      begin
        if( menuitem.genimage == nil)
          @genimage = Genimage.new
          @genimage.restaurant = menuitem.menusection.menu.restaurant
          @genimage.menu = menuitem.menusection.menu
          @genimage.menusection = menuitem.menusection
          @genimage.menuitem = menuitem
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save!
        end
        success_count += 1
      rescue => e
        error_count += 1
        puts "[#{index + 1}/#{total}] Exception processing menu item ##{menuitem.id}: #{e.message}"
      end
      
      # Print progress every 100 records
      if total > 0 && (index + 1) % 100 == 0
        pct = ((index + 1).to_f / total * 100).round(2)
        puts "Progress: #{index + 1}/#{total} (#{pct}%)"
      end
    end
    puts ""
    puts "Processing complete!"
    puts "Total processed: #{total}"
    puts "Successfully saved: #{success_count}"
    puts "Errors: #{error_count}"
  end
end

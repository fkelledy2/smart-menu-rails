namespace :menu_items do
  desc "Iterate through all menu items and save them (useful for triggering callbacks)"
  task reprocess: :environment do
    puts "Starting to process all menu items..."
    
    total = MenuItem.count
    success_count = 0
    error_count = 0
    
    MenuItem.find_each.with_index do |menu_item, index|
      begin
        if( menuitem.genimage == nil)
          @genimage = Genimage.new
          @genimage.restaurant = menuitem.menusection.menu.restaurant
          @genimage.menu = menuitem.menusection.menu
          @genimage.menusection = menuitem.menusection
          @genimage.menuitem = menuitem
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
      end
      rescue => e
        error_count += 1
        puts "[#{index + 1}/#{total}] Exception processing menu item ##{menu_item.id}: #{e.message}"
      end
      
      # Print progress every 100 records
      puts "Progress: #{index + 1}/#{total} (#{((index + 1).to_f / total * 100).round(2)}%)" if (index + 1) % 100 == 0
    end
    
    puts "\nProcessing complete!"
    puts "Total processed: #{total}"
    puts "Successfully saved: #{success_count}"
    puts "Errors: #{error_count}"
  end
end

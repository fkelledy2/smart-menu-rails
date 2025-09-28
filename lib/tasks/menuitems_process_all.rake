namespace :menuitems do
  desc 'Process all menu items by saving them (triggers callbacks and validations)'
  task process_all: :environment do
    puts 'Starting to process all menu items...'

    Menuitem.count
    processed = 0
    successful = 0
    errors = 0

    Menuitem.find_each(batch_size: 100) do |menuitem|
      begin
        if menuitem.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = menuitem.menusection.menu.restaurant
          @genimage.menu = menuitem.menusection.menu
          @genimage.menusection = menuitem.menusection
          @genimage.menuitem = menuitem
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
      rescue StandardError => e
        errors += 1
        print 'X'
        puts "\nException saving menu item ##{menu_item.id}: #{e.message}"
      end

      processed += 1
      print '|' if (processed % 100).zero?
    end

    puts "\n\nProcessing complete!"
    puts "Total processed: #{processed}"
    puts "Successfully saved: #{successful}"
    puts "Errors: #{errors}"
  end
end

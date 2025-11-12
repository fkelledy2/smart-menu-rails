namespace :menu_images do
  desc 'Generate AI images for all menu items. Optionally pass MENU_ID to scope to a single menu: rake menu_images:generate_all[123]'
  task :generate_all, [:menu_id] => :environment do |_t, args|
    # First, ensure all menu items have Genimage records
    puts "Checking for missing Genimage records..."
    
    menuitem_scope = if args[:menu_id].present?
                       puts "Scoping to menu_id=#{args[:menu_id]}"
                       menu = Menu.find(args[:menu_id])
                       menu.menuitems
                     else
                       Menuitem.all
                     end

    missing_count = 0
    created_count = 0
    
    menuitem_scope.find_each do |menuitem|
      if menuitem.genimage.nil?
        missing_count += 1
        begin
          @genimage = Genimage.new
          @genimage.restaurant = menuitem.menusection.menu.restaurant
          @genimage.menu = menuitem.menusection.menu
          @genimage.menusection = menuitem.menusection
          @genimage.menuitem = menuitem
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save!
          created_count += 1
        rescue StandardError => e
          puts "Error creating Genimage for menuitem ##{menuitem.id}: #{e.message}"
        end
      end
    end
    
    puts "Found #{missing_count} menu items without Genimage records"
    puts "Successfully created #{created_count} Genimage records"
    puts ""

    # Now proceed with image generation
    scope = if args[:menu_id].present?
              Genimage.where(menu_id: args[:menu_id])
            else
              Genimage.all
            end

    total = scope.count
    puts "Starting to generate menu item images... (count=#{total})"

    scope.find_each.with_index do |genimage, index|
      puts "Processing genimage ##{genimage.id} (#{index + 1}/#{total})"

      # Skip if the genimage is associated with a wine item
      if genimage.menuitem&.itemtype == 'wine'
        puts '  Skipping wine item'
        next
      end

      # Process the image using the job
      MenuItemImageGeneratorJob.perform_sync(genimage.id)

      # Small delay to avoid rate limiting
      sleep(1) if index < total - 1
    rescue StandardError => e
      puts "Error processing genimage ##{genimage.id}: #{e.message}"
      puts e.backtrace.join("\n") if e.backtrace
    end

    puts 'Finished generating all menu item images!'
  end
end

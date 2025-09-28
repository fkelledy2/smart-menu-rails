namespace :genimages do
  desc 'Update genimages. Optionally pass MENU_ID to scope to a single menu: rake genimages:update_all[123]'
  task :update_all, [:menu_id] => :environment do |_t, args|
    scope = if args[:menu_id].present?
              puts "Scoping to menu_id=#{args[:menu_id]}"
              Genimage.where(menu_id: args[:menu_id])
            else
              Genimage.all
            end

    total = scope.count
    puts "Starting to update genimages... (count=#{total})"

    scope.find_each.with_index do |genimage, index|
      puts "Processing genimage ##{genimage.id} (#{index + 1}/#{total})"

      # Skip if the genimage is associated with a wine item
      if genimage.menuitem&.itemtype == 'wine'
        puts '  Skipping wine item'
        next
      end

      # Process the image using the job
      GenerateImageJob.perform_sync(genimage.id)

      # Small delay to avoid rate limiting
      sleep(1) if index < total - 1
    rescue StandardError => e
      puts "Error processing genimage ##{genimage.id}: #{e.message}"
      puts e.backtrace.join("\n") if e.backtrace
    end

    puts 'Finished updating all genimages!'
  end
end

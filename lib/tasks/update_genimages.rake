namespace :genimages do
  desc "Update all genimages by processing them through GenerateImageJob"
  task update_all: :environment do
    puts "Starting to update all genimages..."
    
    Genimage.find_each.with_index do |genimage, index|
      begin
        puts "Processing genimage ##{genimage.id} (#{index + 1}/#{Genimage.count})"
        
        # Skip if the genimage is associated with a wine item
        if genimage.menuitem&.itemtype == 'wine'
          puts "  Skipping wine item"
          next
        end
        
        # Process the image using the job
        GenerateImageJob.perform_sync(genimage.id)
        
        # Small delay to avoid rate limiting
        sleep(1) if index < Genimage.count - 1
        
      rescue StandardError => e
        puts "Error processing genimage ##{genimage.id}: #{e.message}"
        puts e.backtrace.join("\n") if e.backtrace
      end
    end
    
    puts "Finished updating all genimages!"
  end
end

namespace :menuitems do
  desc "Process all menu items by saving them (triggers callbacks and validations)"
  task process_all: :environment do
    puts "Starting to process all menu items..."
    
    total = Menuitem.count
    processed = 0
    successful = 0
    errors = 0
    
    Menuitem.find_each(batch_size: 100) do |item|
      begin
        if item.save
          successful += 1
          print "."
        else
          errors += 1
          print "E"
          puts "\nError saving menu item ##{item.id}: #{item.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors += 1
        print "X"
        puts "\nException saving menu item ##{item.id}: #{e.message}"
      end
      
      processed += 1
      print "|" if processed % 100 == 0
    end
    
    puts "\n\nProcessing complete!"
    puts "Total processed: #{processed}"
    puts "Successfully saved: #{successful}"
    puts "Errors: #{errors}"
  end
end

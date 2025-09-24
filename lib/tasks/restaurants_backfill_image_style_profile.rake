namespace :restaurants do
  desc "Generate image_style_profile for all restaurants that are missing one"
  task backfill_image_style_profile: :environment do
    puts "Backfilling restaurant image_style_profile..."
    job = GenerateImageJob.new
    count = 0

    Restaurant.find_each do |restaurant|
      begin
        next unless restaurant.respond_to?(:image_style_profile)
        next if restaurant.image_style_profile.present?

        # call the job helper to ensure a style profile exists
        job.send(:ensure_style_profile!, restaurant)
        if restaurant.reload.image_style_profile.present?
          count += 1
          puts "  ✓ Set style profile for Restaurant ##{restaurant.id} - #{restaurant.name}"
        else
          puts "  ~ No profile generated for Restaurant ##{restaurant.id} - #{restaurant.name}"
        end
      rescue => e
        puts "  ✗ Error for Restaurant ##{restaurant.id}: #{e.message}"
      end
    end

    puts "Done. Generated profiles for #{count} restaurants."
  end
end

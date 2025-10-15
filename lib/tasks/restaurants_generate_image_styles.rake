namespace :restaurants do
  desc 'Generate image_style_profile for all restaurants that are missing one'
  task generate_image_styles: :environment do
    puts 'Generating restaurant image style profiles...'
    job = MenuItemImageGeneratorJob.new
    count = 0

    Restaurant.find_each do |restaurant|
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
    rescue StandardError => e
      puts "  ✗ Error for Restaurant ##{restaurant.id}: #{e.message}"
    end

    puts "Done. Generated profiles for #{count} restaurants."
  end
end

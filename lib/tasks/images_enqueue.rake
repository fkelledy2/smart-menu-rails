# lib/tasks/resize_existing_images.rake
namespace :images do
  desc 'Queue image resizing for all existing records'
  task enqueue: :environment do
    Menuitem.where.not(image_data: nil).find_each do |record|
      GenerateImageDerivativesJob.perform_later('Menuitem', record.id)
      puts "Queued image processing for record ##{record.id}"
    end
  end
end

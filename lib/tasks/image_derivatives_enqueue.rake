namespace :image_derivatives do
  desc 'Queue image derivative generation for all existing menu items'
  task enqueue: :environment do
    Menuitem.where.not(image_data: nil).find_each do |record|
      GenerateImageDerivativesJob.perform_later('Menuitem', record.id)
      puts "Queued image processing for record ##{record.id}"
    end
  end
end

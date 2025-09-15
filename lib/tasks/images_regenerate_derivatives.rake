namespace :images do
  desc "Regenerate all image derivatives (thumb, medium, large) for Menuitems and Menusections"
  task regenerate_derivatives: :environment do
    puts "Regenerating Menuitem image derivatives..."
    Menuitem.find_each do |item|
      if item.image_attacher&.file
        item.image_attacher.atomic_persist do
          item.image_attacher.refresh_metadata!
          item.image_attacher.create_derivatives
        end
        puts "Regenerated for Menuitem ##{item.id}"
      end
    end

    puts "Regenerating Menusection image derivatives..."
    Menusection.find_each do |section|
      if section.image_attacher&.file
        section.image_attacher.atomic_persist do
          section.image_attacher.refresh_metadata!
          section.image_attacher.create_derivatives
        end
        puts "Regenerated for Menusection ##{section.id}"
      end
    end

    puts "All derivatives regenerated."
  end
end

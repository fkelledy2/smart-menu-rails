class ProvisionUnclaimedRestaurantJob < ApplicationJob
  queue_as :default

  def perform(discovered_restaurant_id:, provisioning_user_id:)
    discovered = DiscoveredRestaurant.find(discovered_restaurant_id)
    user = User.find(provisioning_user_id)

    admin_user = User.find_by(email: 'admin@mellow.menu') || user

    return if discovered.restaurant_id.present?

    ActiveRecord::Base.transaction do
      restaurant = Restaurant.create!(
        user: admin_user,
        name: discovered.name,
        claim_status: :unclaimed,
        preview_enabled: false,
        preview_indexable: false,
        status: :inactive,
      )

      DiscoveredRestaurantRestaurantSyncService.new(
        discovered_restaurant: discovered,
        restaurant: restaurant,
      ).sync!

      menu = Menu.create!(
        restaurant: restaurant,
        name: 'Menu',
        description: '',
        status: 'active',
        archived: false,
        sequence: 1,
      )

      begin
        best_pdf_source = discovered.menu_sources
          .includes(latest_file_attachment: :blob)
          .find { |ms| ms.source_type.to_s == 'pdf' && ms.latest_file.attached? }

        if best_pdf_source && !menu.pdf_menu_scan.attached?
          menu.pdf_menu_scan.attach(best_pdf_source.latest_file.blob)
        end
      rescue StandardError
        nil
      end

      slug_base = discovered.name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
      slug_base = 'restaurant' if slug_base.blank?

      slug = nil
      10.times do |i|
        candidate = i.zero? ? slug_base : "#{slug_base}-#{SecureRandom.hex(3)}"
        next if Smartmenu.exists?(slug: candidate)

        slug = candidate
        break
      end
      slug ||= "#{slug_base}-#{SecureRandom.hex(4)}"

      Smartmenu.create!(
        restaurant: restaurant,
        menu: menu,
        tablesetting: nil,
        slug: slug,
      )

      discovered.update!(restaurant_id: restaurant.id)
    end

    true
  end
end

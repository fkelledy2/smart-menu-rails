namespace :smartmenu do
  desc "One-off cleanup: normalise participant preferredlocale to restaurant default or nil"
  task cleanup_participant_locales: :environment do
    allowed = I18n.available_locales.map(&:to_s)
    slug = ENV["SMARTMENU_SLUG"]

    puts "Allowed locales: #{allowed.join(", ")}"
    puts slug ? "Scoping cleanup to Smartmenu slug=#{slug}" : "Cleaning up ALL smartmenus"

    if slug
      smartmenu = Smartmenu.find_by(slug: slug)
      unless smartmenu
        puts "Smartmenu with slug=#{slug} not found" and exit(1)
      end
      restaurant = smartmenu.restaurant
      default_locale = restaurant&.defaultLocale&.locale&.downcase
      new_locale = allowed.include?(default_locale) ? default_locale : nil

      puts "Restaurant ##{restaurant&.id} default locale: #{default_locale.inspect} -> using #{new_locale.inspect}"

      Menuparticipant
        .where(smartmenu: smartmenu)
        .where.not(preferredlocale: [nil] + allowed)
        .find_each(batch_size: 100) do |mp|
          puts "Menuparticipant #{mp.id}: #{mp.preferredlocale.inspect} -> #{new_locale.inspect}"
          mp.update_columns(preferredlocale: new_locale)
        end

      Ordrparticipant
        .joins(:ordr)
        .where(ordrs: { menu_id: smartmenu.menu_id, restaurant_id: restaurant.id })
        .where.not(preferredlocale: [nil] + allowed)
        .find_each(batch_size: 100) do |op|
          puts "Ordrparticipant #{op.id}: #{op.preferredlocale.inspect} -> #{new_locale.inspect}"
          op.update_columns(preferredlocale: new_locale)
        end
    else
      # Global cleanup across all restaurants
      Ordrparticipant
        .includes(ordr: :restaurant)
        .where.not(preferredlocale: [nil] + allowed)
        .find_each(batch_size: 100) do |op|
          restaurant = op.ordr&.restaurant
          next unless restaurant

          default_locale = restaurant.defaultLocale&.locale&.downcase
          new_locale = allowed.include?(default_locale) ? default_locale : nil

          puts "Ordrparticipant #{op.id}: #{op.preferredlocale.inspect} -> #{new_locale.inspect} (restaurant ##{restaurant.id})"
          op.update_columns(preferredlocale: new_locale)
        end

      Menuparticipant
        .includes(smartmenu: :restaurant)
        .where.not(preferredlocale: [nil] + allowed)
        .find_each(batch_size: 100) do |mp|
          restaurant = mp.smartmenu&.restaurant
          next unless restaurant

          default_locale = restaurant.defaultLocale&.locale&.downcase
          new_locale = allowed.include?(default_locale) ? default_locale : nil

          puts "Menuparticipant #{mp.id}: #{mp.preferredlocale.inspect} -> #{new_locale.inspect} (restaurant ##{restaurant.id})"
          mp.update_columns(preferredlocale: new_locale)
        end
    end

    puts "Cleanup complete."
  end
end

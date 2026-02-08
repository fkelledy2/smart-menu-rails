namespace :menu_item_search do
  desc 'Reindex semantic search documents for a menu. Usage: rake menu_item_search:reindex[MENU_ID,LOCALE]'
  task :reindex, %i[menu_id locale] => :environment do |_t, args|
    menu_id = args[:menu_id].to_i
    raise ArgumentError, 'menu_id is required' if menu_id <= 0

    locale = args[:locale].presence

    MenuItemSearchIndexJob.perform_async(menu_id, locale)
    puts "Enqueued MenuItemSearchIndexJob for menu_id=#{menu_id}#{" locale=#{locale}" if locale}"
  end

  desc 'Print semantic search index stats. Usage: rake menu_item_search:stats[MENU_ID]'
  task :stats, [:menu_id] => :environment do |_t, args|
    menu_id = args[:menu_id].to_i
    raise ArgumentError, 'menu_id is required' if menu_id <= 0

    menu = Menu.find(menu_id)
    restaurant = menu.restaurant

    locales = Restaurantlocale.where(restaurant_id: restaurant.id, status: 1).pluck(:locale).map { |l| l.to_s.strip.split(/[-_]/).first.to_s.downcase }.filter_map(&:presence).uniq
    locales = ['en'] if locales.empty?

    menuitem_count = Menuitem.joins(:menusection).where(menusections: { menu_id: menu.id }).count
    puts "menu_id=#{menu.id} restaurant_id=#{restaurant.id} menuitems=#{menuitem_count}"

    locales.each do |loc|
      scope = MenuItemSearchDocument.where(menu_id: menu.id, locale: loc)
      total_docs = scope.count
      embedded_docs = scope.where.not(embedding: nil).count
      missing_embeddings = total_docs - embedded_docs
      puts "locale=#{loc} docs=#{total_docs} embedded=#{embedded_docs} missing_embeddings=#{missing_embeddings}"
    end
  end
end

http://localhost:3000/smartmenus/470543c6-f005-4f12-9559-9befc6edb6f3namespace :ocr_imports do
  desc 'Reprocess published OCR imports for a single restaurant. Usage: rake ocr_imports:reprocess_restaurant[restaurant_id,limit,dry_run]'
  task :reprocess_restaurant, [:restaurant_id, :limit, :dry_run] => :environment do |_t, args|
    restaurant_id = args[:restaurant_id]

    if restaurant_id.blank?
      puts '❌ Please provide a restaurant_id: rake ocr_imports:reprocess_restaurant[1]'
      exit 1
    end

    restaurant = Restaurant.find_by(id: restaurant_id)
    unless restaurant
      puts "❌ Restaurant #{restaurant_id} not found"
      exit 1
    end

    limit = args[:limit].to_i
    limit = nil if limit <= 0

    dry_run = args[:dry_run].to_s.downcase
    dry_run = (dry_run == 'true' || dry_run == '1')

    puts "🔧 Reprocessing published OCR imports for restaurant_id=#{restaurant.id} (#{restaurant.name}) dry_run=#{dry_run}"

    # Prefer the latest import per menu to avoid reprocessing older superseded imports.
    imports = OcrMenuImport
      .where(restaurant_id: restaurant.id)
      .where.not(menu_id: nil)
      .completed
      .select('DISTINCT ON (menu_id) ocr_menu_imports.*')
      .order('menu_id, created_at DESC')

    imports = imports.limit(limit) if limit

    selected = imports.to_a
    total = selected.size
    puts "Found #{total} menu(s) with published OCR imports"

    enqueued = 0

    selected.each do |import|
      puts "- import_id=#{import.id} menu_id=#{import.menu_id} created_at=#{import.created_at}"
      next if dry_run

      jid = OcrMenuImportReprocessJob.perform_async(import.id, false)
      puts "  enqueued jid=#{jid}"
      enqueued += 1
    end

    puts "✅ Done. Enqueued #{enqueued} job(s)." if !dry_run
    puts "✅ Dry run complete (no jobs enqueued)." if dry_run
  end
end

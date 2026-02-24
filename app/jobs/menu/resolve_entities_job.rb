class Menu::ResolveEntitiesJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(pipeline_run_id, trigger = nil)
    run = BeveragePipelineRun.find_by(id: pipeline_run_id)
    return unless run

    run.update!(current_step: 'resolve_entities')

    menu = run.menu
    items = menu.menuitems.includes(menusection: :menu)

    resolved = 0
    still_needs_review = 0

    items.find_each do |mi|
      next unless %w[whiskey wine].include?(mi.itemtype)

      class_conf = mi.sommelier_classification_confidence.to_f
      parse_conf = mi.sommelier_parse_confidence.to_f

      # Keep the bar relatively high for auto-resolution in MVP A.
      if class_conf < 0.8 || parse_conf < 0.7
        still_needs_review += 1 if mi.sommelier_needs_review
        next
      end

      parsed = mi.sommelier_parsed_fields.is_a?(Hash) ? mi.sommelier_parsed_fields : {}

      canonical_name = build_canonical_name(mi.itemtype, parsed)
      next if canonical_name.blank?

      product = Product.where(product_type: mi.itemtype, canonical_name: canonical_name).first_or_create!(
        attributes_json: {
          source: 'menuitem_rules',
        },
      )

      explanation = build_explanation(mi.itemtype, parsed)
      link = MenuItemProductLink.where(menuitem_id: mi.id, product_id: product.id).first_or_initialize
      link.resolution_confidence = [class_conf, parse_conf].min
      link.explanations = explanation
      link.save! if link.new_record? || link.changed?

      mi.sommelier_needs_review = false
      mi.save! if mi.changed?

      resolved += 1
    end

    # Keep run counts roughly accurate for UI.
    run.update!(
      items_processed: run.items_processed,
      needs_review_count: Menuitem.joins(menusection: :menu)
        .where(menus: { id: menu.id })
        .where(sommelier_needs_review: true)
        .count,
      unresolved_count: Menuitem.joins(menusection: :menu)
        .where(menus: { id: menu.id })
        .where(sommelier_needs_review: true, itemtype: :beverage)
        .count,
    )

    Menu::EnrichProductsJob.perform_async(run.id, trigger)
  rescue StandardError => e
    run&.update!(status: 'failed', error_summary: "#{e.class}: #{e.message}")
    raise
  end

  private

  def build_canonical_name(category, parsed)
    name = parsed['name_raw'].to_s.strip
    return '' if name.blank?

    parts = [name]
    if category == 'wine'
      # Use producer if extracted and different from raw name
      if parsed['producer'].present? && parsed['producer'] != name
        parts = [parsed['producer']]
      end
      grapes = Array(parsed['grape_variety'])
      parts << grapes.first if grapes.any? && !name.downcase.include?(grapes.first.to_s.downcase)
      parts << parsed['appellation'] if parsed['appellation'].present? && !name.downcase.include?(parsed['appellation'].to_s.downcase)
      vintage = parsed['vintage_year']
      parts << vintage.to_s if vintage.present?
    end

    if category == 'whiskey'
      age = parsed['age_years']
      parts << "#{age}yo" if age.present?
    end

    parts.compact_blank.join(' ')
  end

  def build_explanation(category, parsed)
    fields = []
    fields << "name='#{parsed['name_raw']}'" if parsed['name_raw'].present?
    fields << "vintage=#{parsed['vintage_year']}" if category == 'wine' && parsed['vintage_year'].present?
    fields << "age=#{parsed['age_years']}" if category == 'whiskey' && parsed['age_years'].present?
    fields << "abv=#{parsed['bottling_strength_abv']}" if parsed['bottling_strength_abv'].present?
    "Auto-resolved via rules: #{fields.join(', ')}"
  end
end

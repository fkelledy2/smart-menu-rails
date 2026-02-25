# frozen_string_literal: true

class Menu::GenerateWhiskeyFlightsJob < ApplicationJob
  queue_as :default

  FLIGHT_THEMES = {
    'regional_journey' => { title_template: '%{region} Journey', description: 'Explore a region from light to bold' },
    'peat_spectrum' => { title_template: 'Peat Spectrum', description: 'From gentle smoke to full peat storm' },
    'sherry_showcase' => { title_template: 'Sherry Cask Showcase',  description: 'The influence of sherry wood on whiskey' },
    'age_progression' => { title_template: 'Age Progression',       description: 'See how age transforms the spirit' },
    'world_tour' => { title_template: 'World Tour', description: 'A journey across whiskey-producing nations' },
    'staff_picks' => { title_template: 'Staff Picks Flight', description: 'Our team\'s favourite drams' },
    'newcomer_friendly' => { title_template: 'Newcomer\'s Discovery', description: 'An approachable introduction to whiskey' },
    'cask_explorer' => { title_template: 'Cask Explorer', description: 'How different casks shape flavour' },
  }.freeze

  def perform(menu_id)
    menu = ::Menu.find(menu_id)
    restaurant = menu.restaurant
    max_flights = restaurant.max_whiskey_flights || 5

    items = menu.menuitems
      .joins(:menusection)
      .where('menusections.archived IS NOT TRUE')
      .where(itemtype: :whiskey, status: 'active')
      .to_a

    return if items.size < 6

    generated = 0
    FLIGHT_THEMES.each do |theme_key, config|
      break if generated >= max_flights

      flight_items = select_items_for_theme(theme_key, items)
      next if flight_items.nil? || flight_items.size < 3

      title = build_title(config[:title_template], flight_items)
      narrative = build_narrative(config[:description], flight_items)
      total = flight_items.sum { |fi| fi[:menuitem].price.to_f }.round(2)

      flight = WhiskeyFlight.find_or_initialize_by(menu: menu, theme_key: theme_key)
      next if flight.persisted? && flight.manual?

      flight.assign_attributes(
        title: title,
        narrative: narrative,
        items: flight_items.map.with_index(1) do |fi, pos|
          {
            'menuitem_id' => fi[:menuitem].id,
            'position' => pos,
            'note' => fi[:note],
          }
        end,
        total_price: total,
        source: :ai,
        status: flight.persisted? ? flight.status : :draft,
        generated_at: Time.current,
      )
      flight.save!
      generated += 1
    end

    generated
  end

  private

  def parsed(item)
    pf = item.sommelier_parsed_fields
    pf.is_a?(Hash) ? pf : {}
  end

  def select_items_for_theme(theme_key, items)
    case theme_key
    when 'regional_journey'  then regional_flight(items)
    when 'peat_spectrum'     then peat_spectrum_flight(items)
    when 'sherry_showcase'   then sherry_showcase_flight(items)
    when 'age_progression'   then age_progression_flight(items)
    when 'world_tour'        then world_tour_flight(items)
    when 'staff_picks'       then staff_picks_flight(items)
    when 'newcomer_friendly' then newcomer_flight(items)
    when 'cask_explorer'     then cask_explorer_flight(items)
    end
  end

  def regional_flight(items)
    region_groups = items.group_by { |i| parsed(i)['whiskey_region'] }.reject { |k, _| k.blank? }
    _best_region, region_items = region_groups.max_by { |_, v| v.size }
    return nil unless region_items && region_items.size >= 3

    sorted = region_items.sort_by { |i| parsed(i)['age_years'].to_i }
    picked = [sorted.first, sorted[sorted.size / 2], sorted.last].uniq.first(3)
    return nil if picked.size < 3

    picked.map.with_index do |item, idx|
      notes = ['Start gentle', 'Build complexity', 'Finish bold']
      { menuitem: item, note: notes[idx] }
    end
  end

  def peat_spectrum_flight(items)
    peated = items.select { |i| %w[heavily_peated smoky_coastal].include?(parsed(i)['staff_flavor_cluster']) }
    non_peated = items.select { |i| %w[heavily_peated smoky_coastal].exclude?(parsed(i)['staff_flavor_cluster']) && parsed(i)['staff_flavor_cluster'].present? }

    return nil if peated.empty? || non_peated.empty?

    light = non_peated.min_by { |i| i.price.to_f } || non_peated.first
    medium = items.find { |i| parsed(i)['staff_flavor_cluster'] == 'smoky_coastal' } || peated.first
    heavy = peated.max_by { |i| parsed(i)['bottling_strength_abv'].to_f } || peated.last

    picked = [light, medium, heavy].uniq.first(3)
    return nil if picked.size < 3

    picked.map.with_index do |item, idx|
      notes = ['A gentle introduction with no peat', 'Coastal smoke begins to emerge', 'Full peat intensity']
      { menuitem: item, note: notes[idx] }
    end
  end

  def sherry_showcase_flight(items)
    sherry = items.select { |i| parsed(i)['cask_type']&.include?('sherry') }
    return nil if sherry.size < 3

    sorted = sherry.sort_by { |i| parsed(i)['age_years'].to_i }
    picked = [sorted.first, sorted[sorted.size / 2], sorted.last].uniq.first(3)
    return nil if picked.size < 3

    picked.map.with_index do |item, idx|
      notes = ['Light sherry influence', 'Rich dried fruit character', 'Deep sherry intensity']
      { menuitem: item, note: notes[idx] }
    end
  end

  def age_progression_flight(items)
    aged = items.select { |i| parsed(i)['age_years'].to_i.positive? }.sort_by { |i| parsed(i)['age_years'].to_i }
    return nil if aged.size < 3

    young = aged.first
    mid = aged.find { |i| parsed(i)['age_years'].to_i >= 12 } || aged[aged.size / 2]
    old = aged.last

    picked = [young, mid, old].uniq.first(3)
    return nil if picked.size < 3

    picked.map do |item|
      age = parsed(item)['age_years']
      { menuitem: item, note: "#{age} years — see how time transforms the spirit" }
    end
  end

  def world_tour_flight(items)
    region_groups = items.group_by { |i| parsed(i)['whiskey_region'] }.reject { |k, _| k.blank? }
    return nil if region_groups.keys.size < 3

    picked = region_groups.values.map(&:first).sample(3)
    picked.map do |item|
      region_label = BeverageIntelligence::WhiskeyParser::WHISKEY_REGIONS[parsed(item)['whiskey_region']] || 'Unknown'
      { menuitem: item, note: "From #{region_label}" }
    end
  end

  def staff_picks_flight(items)
    picks = items.select { |i| parsed(i)['staff_pick'] == true }
    return nil if picks.size < 3

    picked = picks.sample(3)
    picked.map { |item| { menuitem: item, note: 'Handpicked by our team' } }
  end

  def newcomer_flight(items)
    friendly = items
      .select { |i| parsed(i)['bottling_strength_abv'].to_f.between?(38, 44) || parsed(i)['bottling_strength_abv'].to_f.zero? }
      .reject { |i| %w[heavily_peated].include?(parsed(i)['staff_flavor_cluster']) }
      .sort_by { |i| i.price.to_f }

    return nil if friendly.size < 3

    picked = friendly.first(3)
    picked.map.with_index do |item, idx|
      notes = ['A smooth, approachable start', 'Building character gently', 'A step into complexity']
      { menuitem: item, note: notes[idx] }
    end
  end

  def cask_explorer_flight(items)
    cask_groups = items.group_by { |i| parsed(i)['cask_type'] }.reject { |k, _| k.blank? }
    return nil if cask_groups.keys.size < 3

    picked = cask_groups.values.map(&:first).sample(3)
    picked.map do |item|
      cask = parsed(item)['cask_type'].to_s.tr('_', ' ').titleize
      { menuitem: item, note: "Matured in #{cask}" }
    end
  end

  def build_title(template, flight_items)
    first_item = flight_items.first[:menuitem]
    region = parsed(first_item)['whiskey_region']
    region_label = BeverageIntelligence::WhiskeyParser::WHISKEY_REGIONS[region] || 'Whiskey'
    format(template, region: region_label)
  end

  def build_narrative(description, flight_items)
    names = flight_items.map { |fi| fi[:menuitem].name }
    "#{description}. Featuring #{names.join(', ')}."
  end
end

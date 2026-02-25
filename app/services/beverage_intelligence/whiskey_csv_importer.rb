# frozen_string_literal: true

require 'csv'

module BeverageIntelligence
  class WhiskeyCsvImporter
    REQUIRED_HEADERS = %w[menu_item_name].freeze
    OPTIONAL_HEADERS = %w[
      whiskey_type whiskey_region distillery cask_type age abv
      staff_flavor_cluster staff_tasting_note staff_pick
    ].freeze
    ALL_HEADERS = (REQUIRED_HEADERS + OPTIONAL_HEADERS).freeze

    Result = Struct.new(:matched, :unmatched, :errors, :total, keyword_init: true)

    def initialize(menu)
      @menu = menu
      @menuitems = menu.menuitems
        .joins(:menusection)
        .where('menusections.archived IS NOT TRUE')
        .where(status: 'active')
        .to_a
    end

    def import(csv_content)
      rows = parse_csv(csv_content)
      return Result.new(matched: [], unmatched: [], errors: ['CSV is empty or has no data rows'], total: 0) if rows.empty?

      matched = []
      unmatched = []
      errors = []

      rows.each_with_index do |row, idx|
        name = row['menu_item_name'].to_s.strip
        if name.blank?
          errors << "Row #{idx + 2}: menu_item_name is blank"
          next
        end

        menuitem = fuzzy_match(name)
        if menuitem.nil?
          unmatched << { row: idx + 2, name: name }
          next
        end

        staff_fields = build_staff_fields(row)
        if staff_fields.empty?
          errors << "Row #{idx + 2}: no tagging fields provided for '#{name}'"
          next
        end

        merged = (menuitem.sommelier_parsed_fields || {}).merge(staff_fields)
        merged['staff_tagged_at'] = Time.current.iso8601
        menuitem.update_columns(sommelier_parsed_fields: merged, updated_at: Time.current)

        matched << { row: idx + 2, name: name, menuitem_id: menuitem.id }
      end

      Result.new(matched: matched, unmatched: unmatched, errors: errors, total: rows.size)
    end

    private

    def parse_csv(content)
      csv = CSV.parse(content, headers: true, liberal_parsing: true, skip_blanks: true)
      missing = REQUIRED_HEADERS - csv.headers.map { |h| h.to_s.strip.downcase }
      raise ArgumentError, "Missing required headers: #{missing.join(', ')}" if missing.any?

      csv.map { |row| row.to_h.transform_keys { |k| k.to_s.strip.downcase } }
    rescue CSV::MalformedCSVError => e
      raise ArgumentError, "Invalid CSV: #{e.message}"
    end

    def fuzzy_match(name)
      target = normalize(name)

      # Exact match first
      exact = @menuitems.find { |mi| normalize(mi.name) == target }
      return exact if exact

      # Token overlap (≥80%)
      target_tokens = target.split(/\s+/).to_set
      best = nil
      best_score = 0.0

      @menuitems.each do |mi|
        item_tokens = normalize(mi.name).split(/\s+/).to_set
        union = (target_tokens | item_tokens).size
        next if union.zero?

        overlap = (target_tokens & item_tokens).size.to_f / union
        if overlap > best_score
          best_score = overlap
          best = mi
        end
      end

      best_score >= 0.5 ? best : nil
    end

    def normalize(str)
      s = str.to_s.downcase
      s = s.gsub(/['`]/, "'").gsub(/[^\w\s']/, ' ')
      # Normalize age patterns: "16yo", "16 y.o.", "16 years old", "16 year old" → "16"
      s = s.gsub(/(\d{1,2})\s*(?:yo|y\.?o\.?|years?\s*old|yr)\b/, '\1')
      s.squish
    end

    def build_staff_fields(row)
      fields = {}
      fields['whiskey_type']        = row['whiskey_type'].strip   if row['whiskey_type'].present?
      fields['whiskey_region']      = row['whiskey_region'].strip if row['whiskey_region'].present?
      fields['distillery']          = row['distillery'].strip     if row['distillery'].present?
      fields['cask_type']           = row['cask_type'].strip      if row['cask_type'].present?
      fields['age_years']           = row['age'].to_i             if row['age'].present? && row['age'].to_i.positive?
      fields['bottling_strength_abv'] = row['abv'].to_f           if row['abv'].present? && row['abv'].to_f.positive?
      fields['staff_flavor_cluster'] = row['staff_flavor_cluster'].strip if row['staff_flavor_cluster'].present?
      fields['staff_tasting_note']  = row['staff_tasting_note'].strip[0, 200] if row['staff_tasting_note'].present?
      fields['staff_pick']          = ActiveModel::Type::Boolean.new.cast(row['staff_pick']) if row['staff_pick'].present?
      fields
    end
  end
end

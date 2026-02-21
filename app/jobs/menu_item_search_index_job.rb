require 'digest'
begin
  require 'pgvector'
rescue LoadError
  Rails.logger.debug { '[MenuItemSearchIndexJob] pgvector not available; vector search indexing disabled' } if defined?(Rails)
end

class MenuItemSearchIndexJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 2

  def perform(menu_id, locale = nil)
    return unless vector_search_enabled?

    ml = SmartMenuMlClient.new
    return unless ml.enabled?

    menu = Menu.find(menu_id)

    restaurant_ids = RestaurantMenu.where(menu_id: menu.id).pluck(:restaurant_id)
    restaurant_ids = [menu.restaurant_id] if restaurant_ids.empty?

    restaurant_ids.uniq.each do |restaurant_id|
      locales = if locale.present?
                  [normalize_locale(locale)]
                else
                  Restaurantlocale.where(restaurant_id: restaurant_id, status: 1).pluck(:locale).map { |l| normalize_locale(l) }
                end

      locales = locales.filter_map(&:presence).uniq
      locales = ['en'] if locales.empty?

      locales.each do |loc|
        index_menu_locale(menu, loc, ml, restaurant_id)
      end
    end
  end

  private

  def vector_search_enabled?
    v = ENV.fetch('SMART_MENU_VECTOR_SEARCH_ENABLED', nil)
    return true if v.nil? || v.to_s.strip == ''

    v.to_s.downcase == 'true'
  end

  def vector_embedding_column?
    @vector_embedding_column ||= begin
      col = ActiveRecord::Base.connection.columns(:menu_item_search_documents).find { |c| c.name == 'embedding' }
      col && col.sql_type.to_s.downcase.include?('vector')
    rescue StandardError
      false
    end
  end

  def index_menu_locale(menu, locale, ml, restaurant_id)
    items = Menuitem.joins(:menusection).where(menusections: { menu_id: menu.id }).includes(:menusection)

    docs = []
    items.find_each do |mi|
      section = mi.menusection
      doc_text = [
        mi.localised_name(locale),
        mi.localised_description(locale),
        section&.localised_name(locale),
        section&.localised_description(locale),
      ].map { |s| s.to_s.strip }.compact_blank.join(' | ')

      content_hash = Digest::SHA256.hexdigest(doc_text)

      docs << {
        menuitem_id: mi.id,
        restaurant_id: restaurant_id,
        menu_id: menu.id,
        locale: locale,
        document_text: doc_text,
        content_hash: content_hash,
      }
    end

    return if docs.empty?

    existing = MenuItemSearchDocument.where(menu_id: menu.id, restaurant_id: restaurant_id, locale: locale).pluck(:menuitem_id, :content_hash).to_h

    to_index = docs.reject { |d| existing[d[:menuitem_id]].to_s == d[:content_hash].to_s }
    return if to_index.empty?

    vectors = nil
    if vector_embedding_column? && defined?(Pgvector::Vector)
      texts = to_index.pluck(:document_text)
      vectors = batch_embed(ml, texts, locale)
      return if vectors.blank?
    end

    now = Time.current

    to_index.each_with_index do |row, idx|
      attrs = {
        restaurant_id: row[:restaurant_id],
        menu_id: row[:menu_id],
        menuitem_id: row[:menuitem_id],
        locale: row[:locale],
        document_text: row[:document_text],
        content_hash: row[:content_hash],
        indexed_at: now,
      }

      if vectors
        vec = vectors[idx]
        next unless vec.is_a?(Array) && vec.any?

        attrs[:embedding] = "[#{vec.join(',')}]"
      else
        attrs[:embedding] = nil
      end

      rec = MenuItemSearchDocument.where(menu_id: menu.id, restaurant_id: restaurant_id, menuitem_id: row[:menuitem_id], locale: locale).first
      if rec
        rec.update!(attrs)
      else
        MenuItemSearchDocument.create!(attrs)
      end
    end
  end

  def batch_embed(ml, texts, locale)
    batch_size = (ENV['SMART_MENU_ML_EMBED_BATCH_SIZE'].presence || 32).to_i
    out = []

    texts.each_slice(batch_size) do |slice|
      vectors = ml.embed(texts: slice, locale: locale)
      return nil unless vectors.is_a?(Array)

      out.concat(vectors)
    end

    out
  rescue StandardError
    nil
  end

  def normalize_locale(locale)
    s = locale.to_s.strip
    s = s.split(/[-_]/).first.to_s.downcase
    s.presence || 'en'
  end
end

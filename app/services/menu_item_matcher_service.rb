require 'digest'
begin
  require 'pgvector'
rescue LoadError
  Rails.logger.debug { '[MenuItemMatcherService] pgvector not available; semantic matcher disabled' } if defined?(Rails)
end

class MenuItemMatcherService
  def initialize(menu_id:, locale:, prefer_menuitem_ids: nil)
    @menu_id = menu_id
    @locale = normalize_locale(locale)
    @prefer_menuitem_ids = Array(prefer_menuitem_ids).map(&:to_s)
    @ml = SmartMenuMlClient.new
  end

  def match(query)
    return nil unless @ml.enabled?
    return nil unless defined?(Pgvector::Vector)
    return nil unless vector_embedding_column?

    q = query.to_s.strip
    return nil if q.blank?

    vectors = @ml.embed(texts: [q], locale: @locale)
    return nil unless vectors.is_a?(Array)

    qv = vectors[0]
    return nil unless qv.is_a?(Array) && qv.any?

    qvec = Pgvector::Vector.new(qv)

    base = MenuItemSearchDocument.where(menu_id: @menu_id, locale: @locale)

    fts = base
      .where("document_tsv @@ plainto_tsquery('simple', ?)", q)
      .order(Arel.sql("ts_rank_cd(document_tsv, plainto_tsquery('simple', #{ActiveRecord::Base.connection.quote(q)})) DESC"))
      .limit(50)

    candidate_scope = if fts.exists?
                        base.where(id: fts.select(:id))
                      else
                        base
                      end

    top = candidate_scope.order(Arel.sql('embedding <=> ?'), qvec).limit(10)

    docs = top.select(:menuitem_id, :document_text).to_a
    return nil if docs.empty?

    unless rerank_enabled?
      best = docs.first
      return nil if best&.menuitem_id.blank?

      return {
        menuitem_id: best.menuitem_id.to_s,
        confidence: 0.0,
        method: 'semantic_vector',
      }
    end

    candidates = docs.map { |d| { id: d.menuitem_id.to_s, text: d.document_text.to_s } }
    ranked = @ml.rerank(query: q, candidates: candidates, locale: @locale)
    return nil unless ranked.is_a?(Array)

    scores = {}
    ranked.each do |row|
      next unless row.is_a?(Hash)

      rid = row['id'] || row[:id]
      sc = row['score'] || row[:score]
      next if rid.blank? || sc.nil?

      scores[rid.to_s] = sc.to_f
    end

    return nil if scores.empty?

    best_id, best_score = scores.max_by { |_id, sc| sc }

    if @prefer_menuitem_ids.include?(best_id)
      best_score += 0.02
    end

    {
      menuitem_id: best_id,
      confidence: best_score,
      method: 'semantic_rerank',
    }
  rescue StandardError
    nil
  end

  private

  def vector_embedding_column?
    @vector_embedding_column ||= begin
      col = ActiveRecord::Base.connection.columns(:menu_item_search_documents).find { |c| c.name == 'embedding' }
      col && col.sql_type.to_s.downcase.include?('vector')
    rescue StandardError
      false
    end
  end

  def rerank_enabled?
    v = ENV.fetch('SMART_MENU_ML_RERANK_ENABLED', nil)
    return true if v.nil? || v.to_s.strip == ''

    v.to_s.downcase == 'true'
  end

  def normalize_locale(locale)
    s = locale.to_s.strip
    s = s.split(/[-_]/).first.to_s.downcase
    s.presence || 'en'
  end
end

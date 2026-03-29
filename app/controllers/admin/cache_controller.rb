class Admin::CacheController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  ALLOWED_CACHE_KEY_PREFIXES = %w[
    menu restaurant smartmenu schema_org menuitem menusection
    advanced_cache identity_cache views/
  ].freeze

  # Pundit authorization
  after_action :verify_authorized

  # GET /admin/cache
  def index
    authorize %i[admin cache]

    @cache_info = AdvancedCacheService.cache_info
    @cache_stats = AdvancedCacheService.cache_stats
    @health_check = AdvancedCacheService.cache_health_check
  end

  # GET /admin/cache/stats
  def stats
    authorize %i[admin cache], :stats?

    respond_to do |format|
      format.json { render json: AdvancedCacheService.cache_stats }
      format.html { redirect_to admin_cache_index_path }
    end
  end

  # POST /admin/cache/warm
  def warm
    authorize %i[admin cache], :warm?

    restaurant_id = params[:restaurant_id]
    result = AdvancedCacheService.warm_critical_caches(restaurant_id)

    if result[:success]
      flash.now[:notice] =
        "Cache warming completed: #{result[:restaurants_warmed]} restaurants in #{result[:duration_ms]}ms"
    else
      flash.now[:alert] = "Cache warming failed: #{result[:error]}"
    end

    respond_to do |format|
      format.json { render json: result }
      format.html { redirect_to admin_cache_index_path }
    end
  end

  # DELETE /admin/cache/clear
  def clear
    authorize %i[admin cache], :clear?

    result = AdvancedCacheService.clear_all_caches
    flash.now[:notice] = "Cleared #{result[:cleared_count]} cache entries"

    respond_to do |format|
      format.json { render json: result }
      format.html { redirect_to admin_cache_index_path }
    end
  end

  # POST /admin/cache/reset_stats
  def reset_stats
    authorize %i[admin cache], :reset_stats?

    AdvancedCacheService.reset_cache_stats
    flash.now[:notice] = 'Cache statistics have been reset'

    respond_to do |format|
      format.json { render json: { success: true } }
      format.html { redirect_to admin_cache_index_path }
    end
  end

  # GET /admin/cache/health
  def health
    authorize %i[admin cache], :health?

    health_check = AdvancedCacheService.cache_health_check

    respond_to do |format|
      format.json { render json: health_check }
      format.html { redirect_to admin_cache_index_path }
    end
  end

  # GET /admin/cache/keys
  def keys
    authorize %i[admin cache], :keys?

    # Restrict patterns to known safe prefixes to prevent admins from scanning
    # for sensitive cached data (tokens, sessions, credentials) via glob patterns.
    raw_pattern = params[:pattern].to_s.presence || '*'
    pattern = if raw_pattern == '*' || ALLOWED_CACHE_KEY_PREFIXES.any? { |p| raw_pattern.start_with?(p) }
                raw_pattern
              else
                Rails.logger.warn("[SECURITY] Admin #{current_user.id} requested cache keys with disallowed pattern: #{raw_pattern}")
                '*'
              end

    limit = params[:limit]&.to_i&.clamp(1, 500) || 100

    cache_keys = AdvancedCacheService.list_cache_keys(pattern, limit: limit)

    respond_to do |format|
      format.json { render json: { keys: cache_keys, pattern: pattern, limit: limit } }
      format.html do
        @cache_keys = cache_keys
        @pattern = pattern
        @limit = limit
      end
    end
  end

  private

end

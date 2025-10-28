# frozen_string_literal: true

# L1 Cache Optimization: Cache Dependency Service
# Manages cache dependencies and intelligent invalidation strategies
class CacheDependencyService
  # Define cache dependency relationships
  DEPENDENCIES = {
    # Restaurant dependencies
    'restaurant:*' => [
      'menu:*',
      'employee:*',
      'order:*',
      'restaurant_dashboard:*',
      'restaurant_orders:*',
      'restaurant_employees:*',
      'order_summary:*',
      'employee_summary:*',
    ],

    # Menu dependencies
    'menu:*' => [
      'menu_full:*',
      'menu_items:*',
      'menu_performance:*',
      'section_items:*',
      'menuitem_analytics:*',
      'menuitem_performance:*',
    ],

    # Order dependencies
    'order:*' => [
      'order_full:*',
      'order_analytics:*',
      'restaurant_orders:*',
      'order_summary:*',
      'user_orders:*',
    ],

    # Employee dependencies
    'employee:*' => [
      'employee_full:*',
      'employee_performance:*',
      'restaurant_employees:*',
      'employee_summary:*',
      'user_employees:*',
    ],

    # User dependencies
    'user:*' => [
      'user_activity:*',
      'user_orders:*',
      'user_employees:*',
    ],
  }.freeze

  # Cache update priorities (higher number = higher priority)
  UPDATE_PRIORITIES = {
    restaurant_dashboard: 10,
    menu_full: 9,
    restaurant_orders: 8,
    order_analytics: 7,
    menu_performance: 6,
    employee_summary: 5,
    user_activity: 4,
    order_full: 3,
    employee_full: 2,
    menuitem_analytics: 1,
  }.freeze

  class << self
    # Invalidate cache with dependencies
    def invalidate_with_dependencies(cache_key, strategy: :cascade)
      Rails.logger.info("[CacheDependencyService] Invalidating cache key: #{cache_key} with strategy: #{strategy}")

      case strategy
      when :cascade
        cascade_invalidate(cache_key)
      when :selective
        selective_invalidate(cache_key)
      when :update
        update_instead_of_invalidate(cache_key)
      else
        Rails.cache.delete(cache_key)
      end
    end

    # Update cache instead of invalidating (more efficient)
    def update_cache_entry(cache_key, fresh_data, expires_in: 30.minutes)
      Rails.logger.debug { "[CacheDependencyService] Updating cache entry: #{cache_key}" }

      Rails.cache.write(cache_key, fresh_data, expires_in: expires_in)

      # Update dependent caches that can be derived from this data
      update_derived_caches(cache_key, fresh_data)
    end

    # Batch invalidate multiple related keys
    def batch_invalidate(cache_keys, strategy: :cascade)
      return if cache_keys.empty?

      Rails.logger.info("[CacheDependencyService] Batch invalidating #{cache_keys.size} cache keys")

      # Group keys by dependency level to optimize invalidation order
      grouped_keys = group_keys_by_dependency_level(cache_keys)

      # Invalidate in dependency order (children first, then parents)
      grouped_keys.sort.reverse_each do |_level, keys|
        keys.each { |key| invalidate_with_dependencies(key, strategy: strategy) }
      end
    end

    # Smart invalidation based on model changes
    def invalidate_for_model_change(model, operation, changed_attributes = [])
      cache_patterns = generate_cache_patterns_for_model(model, operation, changed_attributes)

      Rails.logger.info("[CacheDependencyService] Model change invalidation for #{model.class.name}##{model.id}")

      cache_patterns.each do |pattern|
        invalidate_pattern(pattern)
      end
    end

    # Invalidate cache patterns with Redis pattern matching
    def invalidate_pattern(pattern)
      Rails.logger.debug { "[CacheDependencyService] Invalidating pattern: #{pattern}" }

      if Rails.cache.respond_to?(:delete_matched)
        Rails.cache.delete_matched(pattern)
      else
        # Fallback for cache stores that don't support pattern matching
        RedisPipelineService.bulk_invalidate_patterns([pattern])
      end
    end

    # Get cache dependency tree for analysis
    def dependency_tree(cache_key)
      dependencies = find_dependent_keys(cache_key)

      tree = { key: cache_key, dependencies: [] }

      dependencies.each do |dep_key|
        tree[:dependencies] << dependency_tree(dep_key)
      end

      tree
    end

    # Analyze cache dependency impact
    def analyze_invalidation_impact(cache_key)
      all_dependent_keys = find_all_dependent_keys(cache_key, Set.new)

      {
        primary_key: cache_key,
        direct_dependencies: find_dependent_keys(cache_key).size,
        total_dependencies: all_dependent_keys.size,
        estimated_regeneration_time: estimate_regeneration_time(all_dependent_keys),
        memory_impact: estimate_memory_impact(all_dependent_keys),
      }
    end

    # Preemptive cache warming based on dependencies
    def warm_dependent_caches(cache_key, context = {})
      dependent_keys = find_dependent_keys(cache_key)

      Rails.logger.info("[CacheDependencyService] Warming #{dependent_keys.size} dependent caches for #{cache_key}")

      # Warm caches in priority order
      prioritized_keys = prioritize_cache_keys(dependent_keys)

      prioritized_keys.each do |key, priority|
        warm_cache_key(key, context, priority)
      end
    end

    private

    # Cascade invalidation following dependency tree
    def cascade_invalidate(cache_key)
      # Find all dependent keys
      dependent_keys = find_dependent_keys(cache_key)

      # Invalidate dependents first (bottom-up)
      dependent_keys.each { |dep_key| cascade_invalidate(dep_key) }

      # Then invalidate the primary key
      Rails.cache.delete(cache_key)

      Rails.logger.debug do
        "[CacheDependencyService] Cascade invalidated #{cache_key} and #{dependent_keys.size} dependents"
      end
    end

    # Selective invalidation (only direct dependencies)
    def selective_invalidate(cache_key)
      dependent_keys = find_dependent_keys(cache_key)

      # Invalidate primary key
      Rails.cache.delete(cache_key)

      # Invalidate only direct dependencies
      dependent_keys.each { |dep_key| Rails.cache.delete(dep_key) }

      Rails.logger.debug do
        "[CacheDependencyService] Selectively invalidated #{cache_key} and #{dependent_keys.size} direct dependents"
      end
    end

    # Update instead of invalidate (more efficient for frequently accessed data)
    def update_instead_of_invalidate(cache_key)
      # Try to regenerate the cache value instead of just deleting it
      if cache_key.match?(/restaurant_dashboard:(\d+)/)
        restaurant_id = ::Regexp.last_match(1).to_i
        fresh_data = AdvancedCacheService.cached_restaurant_dashboard(restaurant_id)
        Rails.cache.write(cache_key, fresh_data, expires_in: 15.minutes)
      elsif cache_key.match?(/menu_full:(\d+):/)
        menu_id = ::Regexp.last_match(1).to_i
        # Extract locale and other parameters from key
        locale = cache_key =~ /:([a-z]{2}):/ ? ::Regexp.last_match(1) : 'en'
        include_inactive = cache_key.include?(':true')
        fresh_data = AdvancedCacheService.cached_menu_with_items(menu_id, locale: locale,
                                                                          include_inactive: include_inactive,)
        Rails.cache.write(cache_key, fresh_data, expires_in: 30.minutes)
      else
        # Fall back to regular invalidation
        Rails.cache.delete(cache_key)
      end
    end

    # Find dependent cache keys based on patterns
    def find_dependent_keys(cache_key)
      dependent_patterns = []

      DEPENDENCIES.each do |pattern, dependencies|
        if cache_key_matches_pattern?(cache_key, pattern)
          dependent_patterns.concat(dependencies)
        end
      end

      # Convert patterns to actual keys (this would need Redis KEYS command or similar)
      dependent_patterns.map { |pattern| expand_pattern_to_keys(pattern) }.flatten.uniq
    end

    # Find all dependent keys recursively
    def find_all_dependent_keys(cache_key, visited = Set.new)
      return [] if visited.include?(cache_key)

      visited.add(cache_key)

      direct_deps = find_dependent_keys(cache_key)
      all_deps = direct_deps.dup

      direct_deps.each do |dep_key|
        next if visited.include?(dep_key)

        all_deps.concat(find_all_dependent_keys(dep_key, visited))
      end

      all_deps.uniq
    end

    # Check if cache key matches a pattern
    def cache_key_matches_pattern?(cache_key, pattern)
      # Convert glob pattern to regex
      regex_pattern = pattern.gsub('*', '.*')
      cache_key.match?(/^#{regex_pattern}$/)
    end

    # Expand pattern to actual cache keys (would use Redis KEYS in real implementation)
    def expand_pattern_to_keys(_pattern)
      # This is a simplified implementation
      # In reality, you'd use Redis KEYS command or maintain a key registry
      []
    end

    # Generate cache patterns for model changes
    def generate_cache_patterns_for_model(model, operation, changed_attributes)
      patterns = []

      case model.class.name
      when 'Restaurant'
        patterns << "restaurant:#{model.id}:*"
        patterns << "restaurant_dashboard:#{model.id}"
        patterns << "restaurant_orders:#{model.id}:*"
        patterns << "restaurant_employees:#{model.id}:*"

        if (changed_attributes.include?('name') || operation == :destroy) && model.respond_to?(:user_id)
          patterns << "user_activity:#{model.user_id}:*"
        end

      when 'Menu'
        patterns << "menu:#{model.id}:*"
        patterns << "menu_full:#{model.id}:*"
        patterns << "menu_items:#{model.id}:*"
        patterns << "menu_performance:#{model.id}:*"
        patterns << "restaurant_dashboard:#{model.restaurant_id}"

      when 'Menuitem'
        if model.menusection&.menu
          menu_id = model.menusection.menu.id
          patterns << "menu_full:#{menu_id}:*"
          patterns << "menu_items:#{menu_id}:*"
          patterns << "section_items:#{model.menusection.id}"
          patterns << "menuitem_analytics:#{model.id}"
        end

      when 'Ordr'
        patterns << "order:#{model.id}:*"
        patterns << "order_full:#{model.id}"
        patterns << "restaurant_orders:#{model.restaurant_id}:*"
        patterns << "restaurant_dashboard:#{model.restaurant_id}"
        patterns << "order_analytics:#{model.restaurant_id}:*"

      when 'Employee'
        patterns << "employee:#{model.id}:*"
        patterns << "employee_full:#{model.id}"
        patterns << "restaurant_employees:#{model.restaurant_id}:*"
        patterns << "restaurant_dashboard:#{model.restaurant_id}"
      end

      patterns
    end

    # Group cache keys by dependency level for optimal invalidation order
    def group_keys_by_dependency_level(cache_keys)
      grouped = Hash.new { |h, k| h[k] = [] }

      cache_keys.each do |key|
        level = calculate_dependency_level(key)
        grouped[level] << key
      end

      grouped
    end

    # Calculate dependency level (0 = no dependencies, higher = more dependencies)
    def calculate_dependency_level(cache_key)
      dependent_keys = find_dependent_keys(cache_key)
      return 0 if dependent_keys.empty?

      1 + dependent_keys.map { |dep_key| calculate_dependency_level(dep_key) }.max
    end

    # Update derived caches that can be computed from the primary data
    def update_derived_caches(cache_key, fresh_data)
      # This would contain logic to update caches that can be derived
      # from the fresh data without additional database queries

      if cache_key.match?(/restaurant_dashboard:(\d+)/)
        # Update related summary caches
        update_restaurant_summary_caches(::Regexp.last_match(1).to_i, fresh_data)
      end
    end

    # Update restaurant summary caches
    def update_restaurant_summary_caches(restaurant_id, dashboard_data)
      # Extract summary data from dashboard data
      if dashboard_data[:stats]
        summary_key = "restaurant_summary:#{restaurant_id}"
        Rails.cache.write(summary_key, dashboard_data[:stats], expires_in: 1.hour)
      end
    end

    # Prioritize cache keys for warming
    def prioritize_cache_keys(cache_keys)
      cache_keys.map do |key|
        priority = UPDATE_PRIORITIES.find { |pattern, _| key.include?(pattern.to_s) }&.last || 0
        [key, priority]
      end.sort_by { |_, priority| -priority }
    end

    # Warm individual cache key
    def warm_cache_key(cache_key, _context, priority)
      # This would contain logic to regenerate specific cache keys
      # based on the key pattern and available context

      Rails.logger.debug { "[CacheDependencyService] Warming cache key: #{cache_key} (priority: #{priority})" }

      # Implementation would depend on the specific cache key pattern
    end

    # Estimate regeneration time for cache keys
    def estimate_regeneration_time(cache_keys)
      # Rough estimates based on cache key patterns
      total_time = 0

      cache_keys.each do |key|
        total_time += case key
                      when /restaurant_dashboard/ then 500 # 500ms
                      when /menu_full/ then 300 # 300ms
                      when /order_analytics/ then 1000 # 1s
                      when /menu_performance/ then 800 # 800ms
                      else 100 # 100ms default
                      end
      end

      total_time
    end

    # Estimate memory impact of cache keys
    def estimate_memory_impact(cache_keys)
      # Rough estimates based on cache key patterns
      total_memory = 0

      cache_keys.each do |key|
        total_memory += case key
                        when /restaurant_dashboard/ then 50_000 # 50KB
                        when /menu_full/ then 100_000 # 100KB
                        when /order_analytics/ then 200_000 # 200KB
                        when /menu_performance/ then 75_000 # 75KB
                        else 10_000 # 10KB default
                        end
      end

      total_memory
    end
  end
end

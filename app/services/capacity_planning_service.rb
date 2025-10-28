# frozen_string_literal: true

# Service for capacity planning and infrastructure recommendations
# Provides models for 10x and 100x traffic growth scenarios
class CapacityPlanningService
  # Current baseline metrics
  CURRENT_METRICS = {
    active_restaurants: 100,
    peak_concurrent_users: 1_000,
    avg_orders_per_hour: 5_000,
    database_size_gb: 50,
    redis_cache_gb: 4,
    app_servers: 2,
    app_server_vcpu: 2,
    app_server_ram_gb: 4,
  }.freeze

  # Infrastructure costs (monthly, in USD)
  COSTS = {
    app_server_small: 50,   # 2 vCPU, 4 GB RAM
    app_server_medium: 100, # 4 vCPU, 8 GB RAM
    app_server_large: 200,  # 8 vCPU, 16 GB RAM
    database_small: 200,    # 4 vCPU, 16 GB RAM
    database_medium: 400,   # 8 vCPU, 32 GB RAM
    database_large: 800,    # 16 vCPU, 64 GB RAM
    database_replica: 200,  # Read replica
    redis_small: 50,        # 4 GB
    redis_medium: 150,      # 32 GB
    redis_large: 500,       # 256 GB
    load_balancer: 50,
    cdn: 100,
    message_queue: 50,
  }.freeze

  class << self
    # Calculate infrastructure needs for growth multiplier
    def calculate_capacity(growth_multiplier)
      {
        growth_multiplier: growth_multiplier,
        metrics: calculate_metrics(growth_multiplier),
        infrastructure: calculate_infrastructure(growth_multiplier),
        costs: calculate_costs(growth_multiplier),
        recommendations: generate_recommendations(growth_multiplier),
      }
    end

    # Generate capacity planning report
    def generate_report(growth_multipliers = [1, 10, 100])
      report = {
        generated_at: Time.current,
        current_baseline: CURRENT_METRICS,
        scenarios: {},
      }

      growth_multipliers.each do |multiplier|
        report[:scenarios]["#{multiplier}x"] = calculate_capacity(multiplier)
      end

      report
    end

    # Check if current infrastructure can handle target load
    def can_handle_load?(target_users)
      current_capacity = CURRENT_METRICS[:peak_concurrent_users]
      growth_multiplier = target_users.to_f / current_capacity

      capacity = calculate_capacity(growth_multiplier)

      {
        can_handle: growth_multiplier <= 2, # 2x with current infrastructure
        target_users: target_users,
        growth_multiplier: growth_multiplier.round(2),
        required_infrastructure: capacity[:infrastructure],
        estimated_cost: capacity[:costs][:total_monthly],
      }
    end

    # Get current system utilization metrics
    def current_utilization
      {
        timestamp: Time.current,
        database: database_utilization,
        cache: cache_utilization,
        application: application_utilization,
      }
    end

    private

    def calculate_metrics(multiplier)
      {
        active_restaurants: (CURRENT_METRICS[:active_restaurants] * multiplier).to_i,
        peak_concurrent_users: (CURRENT_METRICS[:peak_concurrent_users] * multiplier).to_i,
        avg_orders_per_hour: (CURRENT_METRICS[:avg_orders_per_hour] * multiplier).to_i,
        database_size_gb: (CURRENT_METRICS[:database_size_gb] * multiplier).to_i,
        redis_cache_gb: (CURRENT_METRICS[:redis_cache_gb] * multiplier * 0.8).to_i, # Cache grows slower
        requests_per_second: ((CURRENT_METRICS[:avg_orders_per_hour] * multiplier) / 3600.0 * 5).to_i, # 5 requests per order
      }
    end

    def calculate_infrastructure(multiplier)
      case multiplier
      when 0..2
        infrastructure_1x
      when 2..5
        infrastructure_5x
      when 5..15
        infrastructure_10x
      else
        infrastructure_100x
      end
    end

    def infrastructure_1x
      {
        app_servers: {
          count: 2,
          type: 'small',
          vcpu: 2,
          ram_gb: 4,
        },
        database: {
          primary: { vcpu: 4, ram_gb: 16, storage_gb: 100 },
          replicas: 0,
        },
        cache: {
          size_gb: 4,
          nodes: 1,
        },
        load_balancer: true,
        cdn: false,
        message_queue: false,
      }
    end

    def infrastructure_5x
      {
        app_servers: {
          count: 4,
          type: 'medium',
          vcpu: 4,
          ram_gb: 8,
        },
        database: {
          primary: { vcpu: 8, ram_gb: 32, storage_gb: 300 },
          replicas: 1,
        },
        cache: {
          size_gb: 16,
          nodes: 2,
        },
        load_balancer: true,
        cdn: true,
        message_queue: false,
      }
    end

    def infrastructure_10x
      {
        app_servers: {
          count: 6,
          type: 'medium',
          vcpu: 4,
          ram_gb: 8,
          autoscaling: { min: 6, max: 12 },
        },
        database: {
          primary: { vcpu: 8, ram_gb: 32, storage_gb: 500 },
          replicas: 2,
        },
        cache: {
          size_gb: 32,
          nodes: 3,
          clustering: true,
        },
        load_balancer: true,
        cdn: true,
        message_queue: true,
      }
    end

    def infrastructure_100x
      {
        app_servers: {
          count: 20,
          type: 'large',
          vcpu: 8,
          ram_gb: 16,
          autoscaling: { min: 20, max: 50 },
          multi_region: true,
        },
        database: {
          primary: { vcpu: 16, ram_gb: 64, storage_gb: 5000 },
          replicas: 6,
          sharding: true,
        },
        cache: {
          size_gb: 256,
          nodes: 6,
          clustering: true,
          multi_region: true,
        },
        load_balancer: true,
        cdn: true,
        message_queue: true,
        additional_services: %w[monitoring log_aggregation security_scanning],
      }
    end

    def calculate_costs(multiplier)
      infra = calculate_infrastructure(multiplier)

      app_cost = case infra[:app_servers][:type]
                 when 'small' then COSTS[:app_server_small]
                 when 'medium' then COSTS[:app_server_medium]
                 when 'large' then COSTS[:app_server_large]
                 end * infra[:app_servers][:count]

      db_cost = case infra[:database][:primary][:vcpu]
                when 4 then COSTS[:database_small]
                when 8 then COSTS[:database_medium]
                else COSTS[:database_large]
                end

      replica_cost = COSTS[:database_replica] * infra[:database][:replicas]

      cache_cost = case infra[:cache][:size_gb]
                   when 0..10 then COSTS[:redis_small]
                   when 11..50 then COSTS[:redis_medium]
                   else COSTS[:redis_large]
                   end

      additional_cost = 0
      additional_cost += COSTS[:load_balancer] if infra[:load_balancer]
      additional_cost += COSTS[:cdn] if infra[:cdn]
      additional_cost += COSTS[:message_queue] if infra[:message_queue]

      total = app_cost + db_cost + replica_cost + cache_cost + additional_cost

      {
        app_servers: app_cost,
        database: db_cost + replica_cost,
        cache: cache_cost,
        additional_services: additional_cost,
        total_monthly: total,
        total_annual: total * 12,
      }
    end

    def generate_recommendations(multiplier)
      recommendations = []

      if multiplier >= 10
        recommendations << 'Implement database sharding for orders table'
        recommendations << 'Deploy multi-region architecture for global performance'
        recommendations << 'Implement CDN for static assets and menu data'
        recommendations << 'Add message queue for async job processing'
        recommendations << 'Implement advanced caching strategies (L1-L4)'
        recommendations << 'Setup comprehensive monitoring and alerting'
      elsif multiplier >= 5
        recommendations << 'Add database read replicas for query distribution'
        recommendations << 'Implement Redis clustering for cache scalability'
        recommendations << 'Enable CDN for static assets'
        recommendations << 'Setup auto-scaling for application servers'
        recommendations << 'Optimize database indexes and queries'
      elsif multiplier >= 2
        recommendations << 'Add one database read replica'
        recommendations << 'Increase Redis cache size'
        recommendations << 'Enable connection pooling optimization'
        recommendations << 'Implement aggressive caching strategies'
      else
        recommendations << 'Current infrastructure is sufficient'
        recommendations << 'Focus on code optimization and caching'
        recommendations << 'Monitor performance metrics regularly'
      end

      recommendations
    end

    def database_utilization
      return {} unless defined?(ActiveRecord)

      pool = ActiveRecord::Base.connection_pool
      active = pool.connections.count(&:in_use?)

      # Use stat method if available (Rails 7.1+), otherwise calculate manually
      available = if pool.respond_to?(:available_connection_count)
                    pool.available_connection_count
                  else
                    pool.size - active
                  end

      {
        pool_size: pool.size,
        active_connections: active,
        available_connections: available,
        utilization_percent: (active.to_f / pool.size * 100).round(2),
      }
    rescue StandardError => e
      Rails.logger.error("Failed to get database utilization: #{e.message}")
      {}
    end

    def cache_utilization
      return {} unless defined?(Rails.cache)

      # Only works with Redis cache, not MemoryStore
      return {} unless Rails.cache.respond_to?(:redis)

      info = Rails.cache.redis.info
      {
        used_memory_mb: (info['used_memory'].to_i / 1024.0 / 1024.0).round(2),
        max_memory_mb: (info['maxmemory'].to_i / 1024.0 / 1024.0).round(2),
        utilization_percent: ((info['used_memory'].to_f / info['maxmemory']) * 100).round(2),
        connected_clients: info['connected_clients'].to_i,
        hit_rate: calculate_cache_hit_rate(info),
      }
    rescue StandardError => e
      Rails.logger.error("Failed to get cache utilization: #{e.message}")
      {}
    end

    def application_utilization
      {
        process_count: `ps aux | grep puma | grep -v grep | wc -l`.strip.to_i,
        memory_usage_mb: `ps aux | grep puma | grep -v grep | awk '{sum+=$6} END {print sum/1024}'`.strip.to_f.round(2),
      }
    rescue StandardError => e
      Rails.logger.error("Failed to get application utilization: #{e.message}")
      {}
    end

    def calculate_cache_hit_rate(info)
      hits = info['keyspace_hits'].to_f
      misses = info['keyspace_misses'].to_f
      total = hits + misses

      return 0.0 if total.zero?

      ((hits / total) * 100).round(2)
    end
  end
end

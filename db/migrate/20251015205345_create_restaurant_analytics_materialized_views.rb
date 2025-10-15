class CreateRestaurantAnalyticsMaterializedViews < ActiveRecord::Migration[7.2]
  def up
    # 1. Restaurant Analytics Summary View - Pre-computed restaurant-level metrics
    execute <<-SQL
      CREATE MATERIALIZED VIEW restaurant_analytics_mv AS
      SELECT 
        r.id as restaurant_id,
        r.name as restaurant_name,
        r.currency,
        
        -- Time-based metrics
        DATE_TRUNC('day', o.created_at) as date,
        DATE_TRUNC('week', o.created_at) as week,
        DATE_TRUNC('month', o.created_at) as month,
        EXTRACT(hour FROM o.created_at) as hour,
        EXTRACT(dow FROM o.created_at) as day_of_week,
        
        -- Order metrics
        COUNT(DISTINCT o.id) as total_orders,
        COUNT(DISTINCT CASE WHEN o.status IN (35, 40) THEN o.id END) as completed_orders,
        COUNT(DISTINCT CASE WHEN o.status = -1 THEN o.id END) as cancelled_orders,
        
        -- Revenue metrics
        COALESCE(SUM(CASE WHEN o.status IN (35, 40) THEN oi.ordritemprice END), 0) as total_revenue,
        COALESCE(AVG(CASE WHEN o.status IN (35, 40) THEN oi.ordritemprice END), 0) as avg_order_value,
        
        -- Customer metrics
        COUNT(DISTINCT o.tablesetting_id) as unique_tables,
        COUNT(DISTINCT CASE WHEN repeat_customers.order_count > 1 THEN o.tablesetting_id END) as repeat_customers
        
      FROM restaurants r
      LEFT JOIN ordrs o ON r.id = o.restaurant_id
      LEFT JOIN ordritems oi ON o.id = oi.ordr_id
      LEFT JOIN (
        SELECT tablesetting_id, restaurant_id, COUNT(*) as order_count
        FROM ordrs 
        WHERE tablesetting_id IS NOT NULL
        GROUP BY tablesetting_id, restaurant_id
      ) repeat_customers ON o.tablesetting_id = repeat_customers.tablesetting_id 
        AND o.restaurant_id = repeat_customers.restaurant_id

      GROUP BY 
        r.id, r.name, r.currency,
        DATE_TRUNC('day', o.created_at),
        DATE_TRUNC('week', o.created_at), 
        DATE_TRUNC('month', o.created_at),
        EXTRACT(hour FROM o.created_at),
        EXTRACT(dow FROM o.created_at);
    SQL

    # 2. Menu Performance Analytics View - Pre-computed menu item performance
    execute <<-SQL
      CREATE MATERIALIZED VIEW menu_performance_mv AS
      SELECT
        r.id as restaurant_id,
        m.id as menu_id,
        m.name as menu_name,
        ms.id as menusection_id,
        ms.name as category_name,
        mi.id as menuitem_id,
        mi.name as item_name,
        mi.price as item_price,
        
        -- Time dimensions
        DATE_TRUNC('day', o.created_at) as date,
        DATE_TRUNC('month', o.created_at) as month,
        
        -- Performance metrics
        COUNT(oi.id) as times_ordered,
        COUNT(oi.id) as total_quantity,
        COALESCE(SUM(oi.ordritemprice), 0) as total_revenue,
        COALESCE(AVG(oi.ordritemprice), 0) as avg_item_revenue,
        
        -- Ranking metrics (for popularity)
        ROW_NUMBER() OVER (
          PARTITION BY r.id, DATE_TRUNC('month', o.created_at) 
          ORDER BY COUNT(oi.id) DESC
        ) as popularity_rank,
        
        ROW_NUMBER() OVER (
          PARTITION BY r.id, DATE_TRUNC('month', o.created_at) 
          ORDER BY COALESCE(SUM(oi.ordritemprice), 0) DESC
        ) as revenue_rank

      FROM restaurants r
      JOIN menus m ON r.id = m.restaurant_id
      JOIN menusections ms ON m.id = ms.menu_id
      JOIN menuitems mi ON ms.id = mi.menusection_id
      LEFT JOIN ordritems oi ON mi.id = oi.menuitem_id
      LEFT JOIN ordrs o ON oi.ordr_id = o.id AND o.status IN (35, 40)

      GROUP BY
        r.id, m.id, m.name, ms.id, ms.name, mi.id, mi.name, mi.price,
        DATE_TRUNC('day', o.created_at),
        DATE_TRUNC('month', o.created_at);
    SQL

    # 3. System Analytics Summary View - Cross-restaurant metrics for admin
    execute <<-SQL
      CREATE MATERIALIZED VIEW system_analytics_mv AS
      SELECT
        -- Time dimensions
        DATE_TRUNC('day', created_at) as date,
        DATE_TRUNC('week', created_at) as week,
        DATE_TRUNC('month', created_at) as month,
        
        -- Restaurant metrics
        COUNT(DISTINCT CASE WHEN entity_type = 'restaurant' THEN entity_id END) as new_restaurants,
        COUNT(DISTINCT CASE WHEN entity_type = 'user' THEN entity_id END) as new_users,
        COUNT(DISTINCT CASE WHEN entity_type = 'menu' THEN entity_id END) as new_menus,
        COUNT(DISTINCT CASE WHEN entity_type = 'menuitem' THEN entity_id END) as new_menuitems,
        
        -- Order metrics
        COUNT(DISTINCT CASE WHEN entity_type = 'order' THEN entity_id END) as total_orders,
        COALESCE(SUM(CASE WHEN entity_type = 'order' THEN revenue END), 0) as total_revenue,
        
        -- Active metrics
        COUNT(DISTINCT CASE WHEN entity_type = 'active_restaurant' THEN entity_id END) as active_restaurants

      FROM (
        SELECT id as entity_id, 'restaurant' as entity_type, created_at, 0 as revenue FROM restaurants
        UNION ALL
        SELECT id as entity_id, 'user' as entity_type, created_at, 0 as revenue FROM users
        UNION ALL
        SELECT id as entity_id, 'menu' as entity_type, created_at, 0 as revenue FROM menus
        UNION ALL
        SELECT id as entity_id, 'menuitem' as entity_type, created_at, 0 as revenue FROM menuitems
        UNION ALL
        SELECT o.id as entity_id, 'order' as entity_type, o.created_at, 
               COALESCE(SUM(oi.ordritemprice), 0) as revenue 
        FROM ordrs o 
        LEFT JOIN ordritems oi ON o.id = oi.ordr_id 
        WHERE o.status IN (35, 40)
        GROUP BY o.id, o.created_at
        UNION ALL
        SELECT DISTINCT r.id as entity_id, 'active_restaurant' as entity_type, o.created_at, 0 as revenue
        FROM restaurants r
        JOIN ordrs o ON r.id = o.restaurant_id
        WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
      ) combined_data

      GROUP BY
        DATE_TRUNC('day', created_at),
        DATE_TRUNC('week', created_at),
        DATE_TRUNC('month', created_at);
    SQL

    # Add indexes for optimal performance
    add_index_sql = <<-SQL
      -- Restaurant Analytics View Indexes
      CREATE INDEX idx_restaurant_analytics_restaurant_date 
        ON restaurant_analytics_mv (restaurant_id, date);
      CREATE INDEX idx_restaurant_analytics_restaurant_month 
        ON restaurant_analytics_mv (restaurant_id, month);
      CREATE INDEX idx_restaurant_analytics_date 
        ON restaurant_analytics_mv (date);
      
      -- Menu Performance View Indexes  
      CREATE INDEX idx_menu_performance_restaurant_date 
        ON menu_performance_mv (restaurant_id, date);
      CREATE INDEX idx_menu_performance_restaurant_month 
        ON menu_performance_mv (restaurant_id, month);
      CREATE INDEX idx_menu_performance_popularity 
        ON menu_performance_mv (restaurant_id, month, popularity_rank);
      CREATE INDEX idx_menu_performance_revenue 
        ON menu_performance_mv (restaurant_id, month, revenue_rank);
      
      -- System Analytics View Indexes
      CREATE INDEX idx_system_analytics_date 
        ON system_analytics_mv (date);
      CREATE INDEX idx_system_analytics_month 
        ON system_analytics_mv (month);
    SQL

    execute add_index_sql
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS system_analytics_mv CASCADE;"
    execute "DROP MATERIALIZED VIEW IF EXISTS menu_performance_mv CASCADE;"
    execute "DROP MATERIALIZED VIEW IF EXISTS restaurant_analytics_mv CASCADE;"
  end
end

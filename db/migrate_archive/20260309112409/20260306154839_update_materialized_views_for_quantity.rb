class UpdateMaterializedViewsForQuantity < ActiveRecord::Migration[7.2]
  def up
    drop_views
    create_restaurant_analytics_mv
    create_menu_performance_mv
    create_system_analytics_mv
    create_dw_orders_mv
    create_indexes
  end

  def down
    drop_views
    recreate_original_restaurant_analytics_views
    recreate_original_dw_orders_mv
  end

  private

  def drop_views
    execute 'DROP MATERIALIZED VIEW IF EXISTS system_analytics_mv CASCADE;'
    execute 'DROP MATERIALIZED VIEW IF EXISTS menu_performance_mv CASCADE;'
    execute 'DROP MATERIALIZED VIEW IF EXISTS restaurant_analytics_mv CASCADE;'
    execute 'DROP MATERIALIZED VIEW IF EXISTS dw_orders_mv CASCADE;'
  end

  def create_indexes
    execute 'CREATE INDEX idx_restaurant_analytics_restaurant_date ON restaurant_analytics_mv (restaurant_id, date);'
    execute 'CREATE INDEX idx_restaurant_analytics_restaurant_month ON restaurant_analytics_mv (restaurant_id, month);'
    execute 'CREATE INDEX idx_restaurant_analytics_date ON restaurant_analytics_mv (date);'
    execute 'CREATE INDEX idx_menu_performance_restaurant_date ON menu_performance_mv (restaurant_id, date);'
    execute 'CREATE INDEX idx_menu_performance_restaurant_month ON menu_performance_mv (restaurant_id, month);'
    execute 'CREATE INDEX idx_menu_performance_popularity ON menu_performance_mv (restaurant_id, month, popularity_rank);'
    execute 'CREATE INDEX idx_menu_performance_revenue ON menu_performance_mv (restaurant_id, month, revenue_rank);'
    execute 'CREATE INDEX idx_system_analytics_date ON system_analytics_mv (date);'
    execute 'CREATE INDEX idx_system_analytics_month ON system_analytics_mv (month);'
  end

  def create_restaurant_analytics_mv
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW restaurant_analytics_mv AS
      SELECT r.id AS restaurant_id,
             r.name AS restaurant_name,
             r.currency,
             DATE_TRUNC('day', o.created_at) AS date,
             DATE_TRUNC('week', o.created_at) AS week,
             DATE_TRUNC('month', o.created_at) AS month,
             EXTRACT(hour FROM o.created_at) AS hour,
             EXTRACT(dow FROM o.created_at) AS day_of_week,
             COUNT(DISTINCT o.id) AS total_orders,
             COUNT(DISTINCT CASE WHEN o.status IN (35, 40) THEN o.id END) AS completed_orders,
             COUNT(DISTINCT CASE WHEN o.status = -1 THEN o.id END) AS cancelled_orders,
             COALESCE(SUM(CASE WHEN o.status IN (35, 40) THEN oi.ordritemprice * oi.quantity END), 0) AS total_revenue,
             COALESCE(SUM(CASE WHEN o.status IN (35, 40) THEN oi.ordritemprice * oi.quantity END) / NULLIF(COUNT(DISTINCT CASE WHEN o.status IN (35, 40) THEN o.id END), 0), 0) AS avg_order_value,
             COUNT(DISTINCT o.tablesetting_id) AS unique_tables,
             COUNT(DISTINCT CASE WHEN repeat_customers.order_count > 1 THEN o.tablesetting_id END) AS repeat_customers
      FROM restaurants r
      LEFT JOIN ordrs o ON r.id = o.restaurant_id
      LEFT JOIN ordritems oi ON o.id = oi.ordr_id
      LEFT JOIN (
        SELECT tablesetting_id, restaurant_id, COUNT(*) AS order_count
        FROM ordrs
        WHERE tablesetting_id IS NOT NULL
        GROUP BY tablesetting_id, restaurant_id
      ) repeat_customers ON o.tablesetting_id = repeat_customers.tablesetting_id
        AND o.restaurant_id = repeat_customers.restaurant_id
      GROUP BY r.id, r.name, r.currency,
               DATE_TRUNC('day', o.created_at), DATE_TRUNC('week', o.created_at), DATE_TRUNC('month', o.created_at),
               EXTRACT(hour FROM o.created_at), EXTRACT(dow FROM o.created_at);
    SQL
  end

  def create_menu_performance_mv
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW menu_performance_mv AS
      SELECT r.id AS restaurant_id,
             m.id AS menu_id,
             m.name AS menu_name,
             ms.id AS menusection_id,
             ms.name AS category_name,
             mi.id AS menuitem_id,
             mi.name AS item_name,
             mi.price AS item_price,
             DATE_TRUNC('day', o.created_at) AS date,
             DATE_TRUNC('month', o.created_at) AS month,
             COUNT(oi.id) AS times_ordered,
             COALESCE(SUM(oi.quantity), 0) AS total_quantity,
             COALESCE(SUM(oi.ordritemprice * oi.quantity), 0) AS total_revenue,
             COALESCE(AVG(oi.ordritemprice), 0) AS avg_item_revenue,
             ROW_NUMBER() OVER (PARTITION BY r.id, DATE_TRUNC('month', o.created_at) ORDER BY COALESCE(SUM(oi.quantity), 0) DESC) AS popularity_rank,
             ROW_NUMBER() OVER (PARTITION BY r.id, DATE_TRUNC('month', o.created_at) ORDER BY COALESCE(SUM(oi.ordritemprice * oi.quantity), 0) DESC) AS revenue_rank
      FROM restaurants r
      JOIN menus m ON r.id = m.restaurant_id
      JOIN menusections ms ON m.id = ms.menu_id
      JOIN menuitems mi ON ms.id = mi.menusection_id
      LEFT JOIN ordritems oi ON mi.id = oi.menuitem_id
      LEFT JOIN ordrs o ON oi.ordr_id = o.id AND o.status IN (35, 40)
      GROUP BY r.id, m.id, m.name, ms.id, ms.name, mi.id, mi.name, mi.price,
               DATE_TRUNC('day', o.created_at), DATE_TRUNC('month', o.created_at);
    SQL
  end

  def create_system_analytics_mv
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW system_analytics_mv AS
      SELECT DATE_TRUNC('day', created_at) AS date,
             DATE_TRUNC('week', created_at) AS week,
             DATE_TRUNC('month', created_at) AS month,
             COUNT(DISTINCT CASE WHEN entity_type = 'restaurant' THEN entity_id END) AS new_restaurants,
             COUNT(DISTINCT CASE WHEN entity_type = 'user' THEN entity_id END) AS new_users,
             COUNT(DISTINCT CASE WHEN entity_type = 'menu' THEN entity_id END) AS new_menus,
             COUNT(DISTINCT CASE WHEN entity_type = 'menuitem' THEN entity_id END) AS new_menuitems,
             COUNT(DISTINCT CASE WHEN entity_type = 'order' THEN entity_id END) AS total_orders,
             COALESCE(SUM(CASE WHEN entity_type = 'order' THEN revenue END), 0) AS total_revenue,
             COUNT(DISTINCT CASE WHEN entity_type = 'active_restaurant' THEN entity_id END) AS active_restaurants
      FROM (
        SELECT id AS entity_id, 'restaurant' AS entity_type, created_at, 0 AS revenue FROM restaurants
        UNION ALL
        SELECT id AS entity_id, 'user' AS entity_type, created_at, 0 AS revenue FROM users
        UNION ALL
        SELECT id AS entity_id, 'menu' AS entity_type, created_at, 0 AS revenue FROM menus
        UNION ALL
        SELECT id AS entity_id, 'menuitem' AS entity_type, created_at, 0 AS revenue FROM menuitems
        UNION ALL
        SELECT o.id AS entity_id, 'order' AS entity_type, o.created_at, COALESCE(SUM(oi.ordritemprice * oi.quantity), 0) AS revenue
        FROM ordrs o
        LEFT JOIN ordritems oi ON o.id = oi.ordr_id
        WHERE o.status IN (35, 40)
        GROUP BY o.id, o.created_at
        UNION ALL
        SELECT DISTINCT r.id AS entity_id, 'active_restaurant' AS entity_type, o.created_at, 0 AS revenue
        FROM restaurants r
        JOIN ordrs o ON r.id = o.restaurant_id
        WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
      ) combined_data
      GROUP BY DATE_TRUNC('day', created_at), DATE_TRUNC('week', created_at), DATE_TRUNC('month', created_at);
    SQL
  end

  def create_dw_orders_mv
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW dw_orders_mv AS
      SELECT o.id AS order_id,
             o."orderedAt" AS ordered_at,
             o."paidAt" AS paid_at,
             ROUND(o.nett::NUMERIC, 2) AS nett_amount,
             ROUND(o.gross::NUMERIC, 2) AS gross_amount,
             ROUND(o.tax::NUMERIC, 2) AS tax_amount,
             ROUND(o.tip::NUMERIC, 2) AS tip_amount,
             ROUND(o.covercharge::NUMERIC, 2) AS covercharge_amount,
             o.status,
             r.id AS restaurant_id,
             r.name AS restaurant_name,
             r.city,
             r.country,
             r.currency,
             m.id AS menu_id,
             m.name AS menu_name,
             e.id AS employee_id,
             e.role,
             t.id AS tablesetting_id,
             t.name AS table_name,
             t.capacity AS table_capacity,
             t."tabletype" AS table_type,
             COALESCE(SUM(oi.quantity), 0) AS total_quantity,
             COALESCE(SUM(oi.ordritemprice * oi.quantity), 0) AS items_revenue,
             COALESCE(AVG(oi.quantity), 0) AS avg_quantity_per_item,
             COALESCE(MAX(oi.quantity), 0) AS max_item_quantity
      FROM ordrs o
      JOIN restaurants r ON o.restaurant_id = r.id
      JOIN menus m ON o.menu_id = m.id
      JOIN employees e ON o.employee_id = e.id
      JOIN tablesettings t ON o.tablesetting_id = t.id
      JOIN ordritems oi ON oi.ordr_id = o.id
      JOIN menuitems mi ON oi.menuitem_id = mi.id
      JOIN menusections ms ON mi.menusection_id = ms.id
      GROUP BY o.id, o."orderedAt", o."deliveredAt", o."paidAt", o.nett, o.gross, o.tax, o.tip, o.covercharge, o.status,
               r.id, r.name, r.city, r.country, r.currency,
               m.id, m.name,
               e.id, e.role,
               t.id, t.name, t.capacity, t."tabletype"
      ORDER BY o.id DESC;
    SQL
  end

  def recreate_original_restaurant_analytics_views
    execute Rails.root.join('db', 'migrate', '20251015205345_create_restaurant_analytics_materialized_views.rb', '20251015205345_create_restaurant_analytics_materialized_views.rb').read.match(/execute <<-SQL\n(.*)\n    SQL/m)[1]
    execute Rails.root.join('db', 'migrate', '20251015205345_create_restaurant_analytics_materialized_views.rb', '20251015205345_create_restaurant_analytics_materialized_views.rb').read.scan(/execute add_index_sql/m).any? ? <<~SQL.squish : ''
      CREATE INDEX idx_restaurant_analytics_restaurant_date ON restaurant_analytics_mv (restaurant_id, date);
      CREATE INDEX idx_restaurant_analytics_restaurant_month ON restaurant_analytics_mv (restaurant_id, month);
      CREATE INDEX idx_restaurant_analytics_date ON restaurant_analytics_mv (date);
      CREATE INDEX idx_menu_performance_restaurant_date ON menu_performance_mv (restaurant_id, date);
      CREATE INDEX idx_menu_performance_restaurant_month ON menu_performance_mv (restaurant_id, month);
      CREATE INDEX idx_menu_performance_popularity ON menu_performance_mv (restaurant_id, month, popularity_rank);
      CREATE INDEX idx_menu_performance_revenue ON menu_performance_mv (restaurant_id, month, revenue_rank);
      CREATE INDEX idx_system_analytics_date ON system_analytics_mv (date);
      CREATE INDEX idx_system_analytics_month ON system_analytics_mv (month);
    SQL
  end

  def recreate_original_dw_orders_mv
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW dw_orders_mv AS
      SELECT o.id AS order_id,
             o."orderedAt" AS ordered_at,
             o."paidAt" AS paid_at,
             ROUND(o.nett::NUMERIC, 2) AS nett_amount,
             ROUND(o.gross::NUMERIC, 2) AS gross_amount,
             ROUND(o.tax::NUMERIC, 2) AS tax_amount,
             ROUND(o.tip::NUMERIC, 2) AS tip_amount,
             ROUND(o.covercharge::NUMERIC, 2) AS covercharge_amount,
             o.status,
             r.id AS restaurant_id,
             r.name AS restaurant_name,
             r.city,
             r.country,
             r.currency,
             m.id AS menu_id,
             m.name AS menu_name,
             e.id AS employee_id,
             e.role,
             t.id AS tablesetting_id,
             t.name AS table_name,
             t.capacity AS table_capacity,
             t."tabletype" AS table_type
      FROM ordrs o
      JOIN restaurants r ON o.restaurant_id = r.id
      JOIN menus m ON o.menu_id = m.id
      JOIN employees e ON o.employee_id = e.id
      JOIN tablesettings t ON o.tablesetting_id = t.id
      JOIN ordritems oi ON oi.ordr_id = o.id
      JOIN menuitems mi ON oi.menuitem_id = mi.id
      JOIN menusections ms ON mi.menusection_id = ms.id
      GROUP BY o.id, o."orderedAt", o."deliveredAt", o."paidAt", o.nett, o.gross, o.tax, o.tip, o.covercharge, o.status,
               r.id, r.name, r.city, r.country, r.currency,
               m.id, m.name,
               e.id, e.role,
               t.id, t.name, t.capacity, t."tabletype"
      ORDER BY o.id desc;
    SQL
  end
end

# Restaurant Analytics Materialized View Implementation Plan

## 🎯 **Objective**
Implement restaurant analytics materialized views to achieve **90% faster analytics queries** across all user roles and complex controllers, reducing query response times from 500ms+ to <100ms.

## 📊 **Current State Analysis**

### **Existing Infrastructure**
- ✅ **Basic materialized view**: `dw_orders_mv` exists with order-level aggregations
- ✅ **Analytics service**: `AnalyticsReportingService` with complex queries
- ✅ **Read replica routing**: `DatabaseRoutingService` for analytics queries
- ✅ **Caching layer**: `AdvancedCacheService` with 85-95% hit rates

### **Performance Bottlenecks Identified**
1. **Complex joins**: Orders → OrderItems → MenuItems → MenuSections (4+ table joins)
2. **Aggregation queries**: Revenue calculations, item popularity, customer insights
3. **Time-based grouping**: Daily/monthly revenue, peak hours analysis
4. **Cross-restaurant analytics**: System-wide reporting for admin dashboard

### **Current Query Performance**
- **Order analytics**: 500-800ms (multiple complex joins)
- **Revenue calculations**: 600-1200ms (aggregations across time periods)
- **Menu performance**: 400-600ms (item popularity and category analysis)
- **Customer insights**: 300-500ms (session-based analytics)

## 🏗️ **Proposed Materialized Views Architecture**

### **1. Restaurant Analytics Summary View**
**Purpose**: Pre-computed restaurant-level metrics for dashboard performance
```sql
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
  COUNT(DISTINCT CASE WHEN o.status = 'completed' THEN o.id END) as completed_orders,
  COUNT(DISTINCT CASE WHEN o.status = 'cancelled' THEN o.id END) as cancelled_orders,
  
  -- Revenue metrics
  COALESCE(SUM(CASE WHEN o.status = 'completed' THEN oi.ordritemprice END), 0) as total_revenue,
  COALESCE(AVG(CASE WHEN o.status = 'completed' THEN oi.ordritemprice END), 0) as avg_order_value,
  
  -- Customer metrics
  COUNT(DISTINCT o.tablesetting_id) as unique_tables,
  COUNT(DISTINCT CASE WHEN repeat_customers.order_count > 1 THEN o.tablesetting_id END) as repeat_customers
  
FROM restaurants r
LEFT JOIN ordrs o ON r.id = o.restaurant_id
LEFT JOIN ordritems oi ON o.id = oi.ordr_id
LEFT JOIN (
  SELECT tablesetting_id, restaurant_id, COUNT(*) as order_count
  FROM ordrs 
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
```

### **2. Menu Performance Analytics View**
**Purpose**: Pre-computed menu item and category performance metrics
```sql
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
  SUM(oi.quantity) as total_quantity,
  SUM(oi.ordritemprice) as total_revenue,
  AVG(oi.ordritemprice) as avg_item_revenue,
  
  -- Ranking metrics (for popularity)
  ROW_NUMBER() OVER (
    PARTITION BY r.id, DATE_TRUNC('month', o.created_at) 
    ORDER BY COUNT(oi.id) DESC
  ) as popularity_rank,
  
  ROW_NUMBER() OVER (
    PARTITION BY r.id, DATE_TRUNC('month', o.created_at) 
    ORDER BY SUM(oi.ordritemprice) DESC
  ) as revenue_rank

FROM restaurants r
JOIN menus m ON r.id = m.restaurant_id
JOIN menusections ms ON m.id = ms.menu_id
JOIN menuitems mi ON ms.id = mi.menusection_id
LEFT JOIN ordritems oi ON mi.id = oi.menuitem_id
LEFT JOIN ordrs o ON oi.ordr_id = o.id AND o.status = 'completed'

GROUP BY
  r.id, m.id, m.name, ms.id, ms.name, mi.id, mi.name, mi.price,
  DATE_TRUNC('day', o.created_at),
  DATE_TRUNC('month', o.created_at);
```

### **3. System Analytics Summary View**
**Purpose**: Cross-restaurant metrics for admin dashboard
```sql
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
  SUM(CASE WHEN entity_type = 'order' THEN revenue END) as total_revenue,
  
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
  WHERE o.status = 'completed'
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
```

## 🔧 **Implementation Strategy**

### **Phase 1: Core Materialized Views (Week 1)**
1. **Create restaurant analytics materialized view**
2. **Create menu performance materialized view**
3. **Create system analytics materialized view**
4. **Add optimized indexes on all views**

### **Phase 2: Service Integration (Week 1)**
1. **Update AnalyticsReportingService** to use materialized views
2. **Create MaterializedViewService** for refresh management
3. **Add performance monitoring** for query improvements

### **Phase 3: Automated Refresh Strategy (Week 2)**
1. **Implement refresh jobs** for different update frequencies
2. **Create refresh monitoring** and alerting
3. **Add intelligent refresh scheduling** based on data changes

### **Phase 4: Advanced Optimizations (Week 2)**
1. **Implement incremental refresh** where possible
2. **Add view-specific indexes** for optimal performance
3. **Create view health monitoring** and maintenance

## 📈 **Expected Performance Improvements**

### **Query Performance Targets**
- **Restaurant analytics**: 500ms → 50ms (90% improvement)
- **Menu performance**: 400ms → 40ms (90% improvement)
- **System analytics**: 800ms → 80ms (90% improvement)
- **Dashboard loading**: 2-3s → 200-300ms (85-90% improvement)

### **System Benefits**
- **Reduced database load**: 60-70% reduction in complex query execution
- **Improved user experience**: Near-instantaneous dashboard loading
- **Better scalability**: Views handle increased data volume efficiently
- **Enhanced caching**: Materialized views work excellently with existing cache layer

## 🔄 **Refresh Strategy**

### **Refresh Frequencies**
- **Restaurant analytics**: Every 15 minutes (high-frequency updates)
- **Menu performance**: Every 30 minutes (moderate updates)
- **System analytics**: Every hour (low-frequency updates)

### **Refresh Triggers**
- **Time-based**: Scheduled refresh jobs
- **Event-based**: Trigger refresh on significant data changes
- **Manual**: Admin-triggered refresh for immediate updates

### **Refresh Monitoring**
- **Performance tracking**: Monitor refresh execution time
- **Data freshness**: Track last refresh timestamp
- **Error handling**: Alert on refresh failures

## 🛡️ **Risk Mitigation**

### **Data Consistency**
- **Transactional refresh**: Ensure atomic view updates
- **Fallback queries**: Use original queries if views are unavailable
- **Data validation**: Verify view data accuracy against source tables

### **Performance Impact**
- **Off-peak refresh**: Schedule intensive refreshes during low-traffic periods
- **Incremental updates**: Minimize refresh overhead where possible
- **Resource monitoring**: Track refresh impact on database performance

### **Maintenance**
- **View versioning**: Support schema changes without downtime
- **Backup strategy**: Include materialized views in backup procedures
- **Documentation**: Maintain comprehensive view documentation

## 🎯 **Success Metrics**

### **Performance Metrics**
- [ ] **90% query time reduction** for analytics queries
- [ ] **Sub-100ms response times** for dashboard endpoints
- [ ] **60-70% reduction** in database CPU usage during analytics
- [ ] **95%+ cache hit rates** when combined with existing cache layer

### **Business Metrics**
- [ ] **Improved user experience** - faster dashboard loading
- [ ] **Better decision making** - real-time analytics availability
- [ ] **Reduced infrastructure costs** - lower database resource usage
- [ ] **Enhanced scalability** - support for 10x more concurrent analytics users

## 📋 **Implementation Checklist**

### **Database Changes**
- [ ] Create restaurant_analytics_mv materialized view
- [ ] Create menu_performance_mv materialized view  
- [ ] Create system_analytics_mv materialized view
- [ ] Add optimized indexes on all materialized views
- [ ] Create refresh management procedures

### **Application Changes**
- [ ] Create MaterializedViewService for refresh management
- [ ] Update AnalyticsReportingService to use materialized views
- [ ] Create refresh jobs for automated updates
- [ ] Add performance monitoring and alerting
- [ ] Update tests to cover materialized view functionality

### **Infrastructure Changes**
- [ ] Schedule automated refresh jobs
- [ ] Set up monitoring and alerting for view health
- [ ] Configure backup procedures for materialized views
- [ ] Document operational procedures

This implementation will provide the foundation for 90% faster analytics queries while maintaining data accuracy and system reliability.

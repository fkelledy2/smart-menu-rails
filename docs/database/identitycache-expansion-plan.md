# IdentityCache Expansion Plan - Advanced Caching Implementation

## 🎯 **Current Status Analysis**

### ✅ **Models WITH IdentityCache (25 models)**
- Core business models: `Restaurant`, `Menu`, `Menuitem`, `Menusection`, `Ordr`, `Ordritem`
- Configuration models: `Tax`, `Size`, `Tip`, `Tablesetting`, `Allergyn`, `Track`
- Association mappings: `MenuitemAllergynMapping`, `MenuitemSizeMapping`, `OrdrparticipantAllergynFilter`
- Localization: `Restaurantlocale`, `Menulocale`, `Menuitemlocale`, `Menusectionlocale`
- Staff & operations: `Employee`, `Ordrparticipant`, `Ordraction`
- System models: `Smartmenu`, `Testimonial`, `OcrMenuImport`, `Genimage`

### ❌ **Models MISSING IdentityCache (12 high-priority models)**
- **User management**: `User`, `Userplan`, `Plan`, `Feature`, `FeaturesPlan`
- **Content & operations**: `Ingredient`, `Tag`, `Contact`, `Announcement`
- **Complex mappings**: `MenuitemIngredientMapping`, `MenuitemTagMapping`, `Ordritemnote`
- **System models**: `Inventory`, `OnboardingSession`, `Metric`

### 🔧 **Models with INCOMPLETE IdentityCache (optimization needed)**
- Missing `cache_has_many` associations
- Suboptimal cache index strategies
- Missing composite index caching

---

## 📋 **IMPLEMENTATION PLAN**

## **Phase 1: Add IdentityCache to Missing Core Models (Week 1)**

### **Priority 1A: User & Authentication Models**

#### **User Model Enhancement**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  include IdentityCache
  
  # Existing devise configuration...
  
  # IdentityCache configuration
  cache_index :id
  cache_index :email, unique: true
  cache_index :confirmation_token, unique: true
  cache_index :reset_password_token, unique: true
  
  # Cache associations
  cache_has_many :restaurants, embed: :ids
  cache_has_many :userplans, embed: :ids
  cache_has_many :testimonials, embed: :ids
  cache_has_many :employees, embed: :ids
  cache_has_one :onboarding_session, embed: :id
end
```

#### **Plan & Feature Models**
```ruby
# app/models/plan.rb
class Plan < ApplicationRecord
  include IdentityCache
  
  # IdentityCache configuration
  cache_index :id
  cache_index :status
  cache_index :name, unique: true
  
  # Cache associations
  cache_has_many :userplans, embed: :ids
  cache_has_many :features_plans, embed: :ids
end

# app/models/feature.rb
class Feature < ApplicationRecord
  include IdentityCache
  
  # IdentityCache configuration
  cache_index :id
  cache_index :name, unique: true
  cache_index :category
  
  # Cache associations
  cache_has_many :features_plans, embed: :ids
end
```

### **Priority 1B: Content & Ingredient Models**

#### **Ingredient Model Enhancement**
```ruby
# app/models/ingredient.rb
class Ingredient < ApplicationRecord
  include IdentityCache
  
  # Add missing associations
  belongs_to :restaurant
  has_many :menuitem_ingredient_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_ingredient_mappings
  
  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :name
  cache_index :category
  
  # Cache associations
  cache_belongs_to :restaurant
  cache_has_many :menuitem_ingredient_mappings, embed: :ids
end
```

#### **Tag Model Enhancement**
```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  include IdentityCache
  
  # Add restaurant association for proper scoping
  belongs_to :restaurant
  has_many :menuitem_tag_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_tag_mappings
  
  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :name
  cache_index :color
  
  # Cache associations
  cache_belongs_to :restaurant
  cache_has_many :menuitem_tag_mappings, embed: :ids
end
```

---

## **Phase 2: Optimize Existing IdentityCache Implementation (Week 2)**

### **Priority 2A: Add Missing Association Caching**

#### **Restaurant Model Optimization**
```ruby
# app/models/restaurant.rb - Add missing associations
class Restaurant < ApplicationRecord
  # ... existing code ...
  
  # Enhanced cache associations
  cache_has_many :menus, embed: :ids
  cache_has_many :tablesettings, embed: :ids  
  cache_has_many :employees, embed: :ids
  cache_has_many :taxes, embed: :ids
  cache_has_many :tips, embed: :ids
  cache_has_many :allergyns, embed: :ids
  cache_has_many :sizes, embed: :ids
  cache_has_many :ingredients, embed: :ids  # NEW
  cache_has_many :tags, embed: :ids         # NEW
  cache_has_many :tracks, embed: :ids       # NEW
  cache_has_many :inventories, embed: :ids  # NEW
  cache_has_many :ordrs, embed: :ids        # NEW
  cache_has_many :smartmenus, embed: :ids   # NEW
  cache_has_one :genimage, embed: :id
end
```

#### **Menu Model Optimization**
```ruby
# app/models/menu.rb - Add missing associations
class Menu < ApplicationRecord
  # ... existing code ...
  
  # Enhanced cache associations
  cache_has_many :menusections, embed: :ids
  cache_has_many :menuavailabilities, embed: :ids
  cache_has_many :menulocales, embed: :ids
  cache_has_many :ordrs, embed: :ids           # NEW
  cache_has_many :smartmenus, embed: :ids      # NEW
  cache_has_one :genimage, embed: :id
  cache_belongs_to :restaurant
end
```

### **Priority 2B: Add Composite Index Caching**

#### **Enhanced Index Strategies**
```ruby
# app/models/menuitem.rb - Add composite indexes
class Menuitem < ApplicationRecord
  # ... existing code ...
  
  # Enhanced IdentityCache configuration
  cache_index :id
  cache_index :menusection_id
  cache_index [:menusection_id, :status]      # NEW: For active items per section
  cache_index [:menusection_id, :position]    # NEW: For ordered items
  cache_index :status                         # NEW: For global status queries
  
  # Enhanced cache associations
  cache_belongs_to :menusection
  cache_has_many :menuitemlocales, embed: :ids
  cache_has_many :menuitem_allergyn_mappings, embed: :ids
  cache_has_many :menuitem_size_mappings, embed: :ids
  cache_has_many :menuitem_ingredient_mappings, embed: :ids  # NEW
  cache_has_many :menuitem_tag_mappings, embed: :ids         # NEW
  cache_has_many :ordritems, embed: :ids                     # NEW
  cache_has_many :inventories, embed: :ids                   # NEW
end
```

---

## **Phase 3: Advanced Caching Patterns (Week 3)**

### **Priority 3A: Query Result Caching Service**

#### **Create Advanced Cache Service**
```ruby
# app/services/advanced_cache_service.rb
class AdvancedCacheService
  class << self
    # Cache complex menu queries
    def cached_menu_with_items(menu_id, locale: 'en')
      Rails.cache.fetch("menu_full:#{menu_id}:#{locale}", expires_in: 30.minutes) do
        menu = Menu.fetch(menu_id)
        {
          menu: menu,
          sections: menu.fetch_menusections.map do |section|
            {
              section: section,
              items: section.fetch_menuitems.select { |item| item.status == 'active' }
            }
          end
        }
      end
    end
    
    # Cache restaurant dashboard data
    def cached_restaurant_dashboard(restaurant_id)
      Rails.cache.fetch("restaurant_dashboard:#{restaurant_id}", expires_in: 15.minutes) do
        restaurant = Restaurant.fetch(restaurant_id)
        {
          restaurant: restaurant,
          active_menus: restaurant.fetch_menus.select { |m| m.status == 'active' },
          recent_orders: restaurant.fetch_ordrs.select { |o| o.created_at > 24.hours.ago },
          staff_count: restaurant.fetch_employees.count,
          table_count: restaurant.fetch_tablesettings.count
        }
      end
    end
    
    # Cache order analytics
    def cached_order_analytics(restaurant_id, date_range)
      cache_key = "order_analytics:#{restaurant_id}:#{date_range.begin}:#{date_range.end}"
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        restaurant = Restaurant.fetch(restaurant_id)
        orders = restaurant.fetch_ordrs.select { |o| date_range.cover?(o.created_at) }
        
        {
          total_orders: orders.count,
          total_revenue: orders.sum(&:total_amount),
          average_order_value: orders.any? ? orders.sum(&:total_amount) / orders.count : 0,
          popular_items: calculate_popular_items(orders)
        }
      end
    end
    
    private
    
    def calculate_popular_items(orders)
      item_counts = Hash.new(0)
      orders.each do |order|
        order.fetch_ordritems.each do |item|
          menuitem = item.fetch_menuitem
          item_counts[menuitem.name] += item.quantity
        end
      end
      item_counts.sort_by { |_, count| -count }.first(10)
    end
  end
end
```

### **Priority 3B: Cache Warming Strategies**

#### **Create Cache Warming Service**
```ruby
# app/services/cache_warming_service.rb
class CacheWarmingService
  class << self
    # Warm cache for restaurant and its core data
    def warm_restaurant_cache(restaurant_id)
      restaurant = Restaurant.fetch(restaurant_id)
      
      # Warm primary associations
      restaurant.fetch_menus
      restaurant.fetch_employees
      restaurant.fetch_tablesettings
      restaurant.fetch_allergyns
      restaurant.fetch_sizes
      restaurant.fetch_taxes
      restaurant.fetch_tips
      
      # Warm menu data
      restaurant.fetch_menus.each do |menu|
        warm_menu_cache(menu.id)
      end
      
      Rails.logger.info("Cache warmed for restaurant #{restaurant_id}")
    end
    
    # Warm cache for menu and its items
    def warm_menu_cache(menu_id)
      menu = Menu.fetch(menu_id)
      
      # Warm menu associations
      menu.fetch_menusections.each do |section|
        section.fetch_menuitems.each do |item|
          # Warm item associations
          item.fetch_menuitemlocales
          item.fetch_menuitem_allergyn_mappings
          item.fetch_menuitem_size_mappings
        end
      end
      
      Rails.logger.info("Cache warmed for menu #{menu_id}")
    end
    
    # Warm cache for active orders
    def warm_active_orders_cache(restaurant_id)
      restaurant = Restaurant.fetch(restaurant_id)
      active_orders = restaurant.fetch_ordrs.select { |o| o.status.in?(['opened', 'confirmed']) }
      
      active_orders.each do |order|
        order.fetch_ordritems
        order.fetch_ordrparticipants
        order.fetch_ordractions
      end
      
      Rails.logger.info("Cache warmed for #{active_orders.count} active orders")
    end
  end
end
```

---

## **Phase 4: Cache Invalidation & Monitoring (Week 4)**

### **Priority 4A: Smart Cache Invalidation**

#### **Create Cache Invalidation Service**
```ruby
# app/services/cache_invalidation_service.rb
class CacheInvalidationService
  class << self
    # Invalidate restaurant-related caches
    def invalidate_restaurant_cache(restaurant_id)
      restaurant = Restaurant.fetch(restaurant_id)
      
      # Invalidate dashboard cache
      Rails.cache.delete("restaurant_dashboard:#{restaurant_id}")
      
      # Invalidate menu caches
      restaurant.fetch_menus.each do |menu|
        invalidate_menu_cache(menu.id)
      end
      
      # Invalidate analytics caches
      Rails.cache.delete_matched("order_analytics:#{restaurant_id}:*")
      
      Rails.logger.info("Invalidated caches for restaurant #{restaurant_id}")
    end
    
    # Invalidate menu-related caches
    def invalidate_menu_cache(menu_id)
      Rails.cache.delete_matched("menu_full:#{menu_id}:*")
      Rails.logger.info("Invalidated caches for menu #{menu_id}")
    end
    
    # Invalidate order-related caches
    def invalidate_order_cache(restaurant_id)
      Rails.cache.delete_matched("order_analytics:#{restaurant_id}:*")
      Rails.cache.delete("restaurant_dashboard:#{restaurant_id}")
    end
  end
end
```

### **Priority 4B: Cache Performance Monitoring**

#### **Enhanced Cache Monitoring**
```ruby
# config/initializers/identity_cache_monitoring.rb
if Rails.env.production?
  # Monitor IdentityCache performance
  ActiveSupport::Notifications.subscribe('cache_fetch_hit.identity_cache') do |name, start, finish, id, payload|
    duration = finish - start
    Rails.logger.info(
      "IdentityCache HIT: #{payload[:key]} (#{duration.round(3)}s)"
    )
  end
  
  ActiveSupport::Notifications.subscribe('cache_fetch_miss.identity_cache') do |name, start, finish, id, payload|
    duration = finish - start
    Rails.logger.warn(
      "IdentityCache MISS: #{payload[:key]} (#{duration.round(3)}s)"
    )
  end
  
  # Track cache hit rates
  class IdentityCacheMetrics
    @@hits = 0
    @@misses = 0
    
    def self.record_hit
      @@hits += 1
    end
    
    def self.record_miss
      @@misses += 1
    end
    
    def self.hit_rate
      total = @@hits + @@misses
      return 0 if total == 0
      (@@hits.to_f / total * 100).round(2)
    end
    
    def self.stats
      {
        hits: @@hits,
        misses: @@misses,
        hit_rate: hit_rate
      }
    end
  end
end
```

---

## **Phase 5: Controller Integration & Optimization (Week 5)**

### **Priority 5A: Update Controllers to Use Cached Methods**

#### **Restaurants Controller Optimization**
```ruby
# app/controllers/restaurants_controller.rb
class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.fetch(params[:id])
    @dashboard_data = AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)
    
    # Warm cache for next requests
    CacheWarmingService.warm_restaurant_cache(@restaurant.id) if stale?(@restaurant)
  end
  
  def update
    @restaurant = Restaurant.fetch(params[:id])
    
    if @restaurant.update(restaurant_params)
      # Invalidate related caches
      CacheInvalidationService.invalidate_restaurant_cache(@restaurant.id)
      redirect_to @restaurant
    else
      render :edit
    end
  end
end
```

#### **Menus Controller Optimization**
```ruby
# app/controllers/menus_controller.rb
class MenusController < ApplicationController
  def show
    @menu = Menu.fetch(params[:id])
    @menu_data = AdvancedCacheService.cached_menu_with_items(
      @menu.id, 
      locale: params[:locale] || 'en'
    )
  end
  
  def update
    @menu = Menu.fetch(params[:id])
    
    if @menu.update(menu_params)
      # Invalidate menu caches
      CacheInvalidationService.invalidate_menu_cache(@menu.id)
      redirect_to @menu
    else
      render :edit
    end
  end
end
```

---

## **📊 SUCCESS METRICS & MONITORING**

### **Performance Targets**
- **Cache Hit Rate**: >90% for IdentityCache operations
- **Query Reduction**: 70% reduction in database queries for cached operations
- **Response Time**: 50% improvement in page load times for cached pages
- **Memory Usage**: Efficient Redis memory utilization with <20% increase

### **Monitoring Dashboard**
```ruby
# app/controllers/health_controller.rb - Add cache stats endpoint
def cache_stats
  render json: {
    identity_cache: IdentityCacheMetrics.stats,
    redis_info: Rails.cache.redis.info,
    cache_keys_count: Rails.cache.redis.dbsize,
    memory_usage: Rails.cache.redis.info['used_memory_human']
  }
end
```

### **Testing Strategy**
- **Unit Tests**: Cache behavior for each model
- **Integration Tests**: End-to-end cache warming and invalidation
- **Performance Tests**: Before/after benchmarks
- **Load Tests**: Cache performance under high traffic

---

## **🚀 IMPLEMENTATION TIMELINE**

### **Week 1: Core Model Enhancement**
- [ ] Add IdentityCache to User, Plan, Feature models
- [ ] Add IdentityCache to Ingredient, Tag models
- [ ] Create missing association mappings
- [ ] Write comprehensive tests

### **Week 2: Association Optimization**
- [ ] Enhance Restaurant model cache associations
- [ ] Optimize Menu and Menuitem cache strategies
- [ ] Add composite index caching
- [ ] Update existing model tests

### **Week 3: Advanced Caching Services**
- [ ] Implement AdvancedCacheService
- [ ] Create CacheWarmingService
- [ ] Add query result caching patterns
- [ ] Performance testing and optimization

### **Week 4: Cache Management**
- [ ] Implement CacheInvalidationService
- [ ] Add cache performance monitoring
- [ ] Create cache health check endpoints
- [ ] Documentation and runbooks

### **Week 5: Controller Integration**
- [ ] Update controllers to use cached methods
- [ ] Implement cache warming strategies
- [ ] Add cache invalidation triggers
- [ ] Final performance validation

**Expected Completion**: End of Week 5
**Success Criteria**: >90% cache hit rate, 50% response time improvement, 70% query reduction

This comprehensive plan will significantly enhance the application's caching strategy while maintaining data consistency and providing robust monitoring capabilities.

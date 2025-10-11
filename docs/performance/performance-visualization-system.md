# Performance Visualization System

## 🎯 **Overview**

A comprehensive, reusable performance visualization system built with Bootstrap 5 and Chart.js for the Smart Menu application. This system provides consistent, beautiful performance dashboards across all `/performance` endpoints.

## 🏗️ **Architecture**

### **Component-Based Design**
The system uses modular, reusable components that can be easily integrated into any performance endpoint:

```erb
<%= render 'shared/performance_dashboard', 
    title: "Restaurant Performance Dashboard", 
    subtitle: @restaurant.name,
    performance_data: @performance_data,
    base_path: restaurant_performance_path(@restaurant),
    icon: "fas fa-store" %>
```

### **Reusable Components**

#### **1. Main Dashboard Component**
- **File**: `app/views/shared/_performance_dashboard.html.erb`
- **Purpose**: Main container with header, period selector, and component orchestration
- **Features**: Configurable title, subtitle, icon, and base path for navigation

#### **2. Key Performance Indicators (KPIs)**
- **File**: `app/views/shared/_performance_kpis.html.erb`
- **Purpose**: Four-card KPI display with icons and color coding
- **Metrics**: Cache hit rate, response time, database queries, user activity

#### **3. Performance Charts**
- **File**: `app/views/shared/_performance_charts.html.erb`
- **Purpose**: Chart containers with consistent styling and layout
- **Charts**: Cache performance, database distribution, response times, user activity, system metrics

#### **4. Details Table**
- **File**: `app/views/shared/_performance_details_table.html.erb`
- **Purpose**: Comprehensive performance metrics table with status badges
- **Features**: Color-coded status indicators, detailed descriptions, threshold-based alerts

#### **5. Chart.js Integration**
- **File**: `app/views/shared/_performance_charts_script.html.erb`
- **Purpose**: JavaScript for Chart.js initialization and configuration
- **Features**: Responsive charts, consistent styling, error handling, auto-refresh capability

## 📊 **Chart Types & Visualizations**

### **1. Cache Performance - Doughnut Chart**
```javascript
type: 'doughnut'
data: ['Cache Hits', 'Cache Misses']
colors: ['#198754', '#dc3545'] // Green for hits, red for misses
```

### **2. Database Query Distribution - Bar Chart**
```javascript
type: 'bar'
data: ['Primary Database', 'Replica Database']
colors: ['#0d6efd', '#20c997'] // Blue for primary, teal for replica
```

### **3. Response Time Metrics - Bar Chart**
```javascript
type: 'bar'
data: ['Average Response', 'Maximum Response']
colors: ['#17a2b8', '#fd7e14'] // Info blue and orange
```

### **4. User Activity - Radar Chart**
```javascript
type: 'radar'
data: ['Sessions', 'Visitors', 'Page Views', 'Avg Duration', 'Engagement']
color: '#ffc107' // Warning yellow
```

### **5. System Metrics - Line Chart**
```javascript
type: 'line'
data: ['Memory', 'CPU', 'Disk', 'Connections', 'Jobs']
color: '#dc3545' // Danger red
```

## 🎨 **Bootstrap 5 Styling**

### **Design System**
- **Cards**: `border-0 shadow-sm` for modern, clean appearance
- **Colors**: Bootstrap 5 semantic colors (primary, success, info, warning, danger)
- **Icons**: Font Awesome 6 with consistent sizing and spacing
- **Typography**: Inter font family with proper hierarchy
- **Spacing**: Consistent margin/padding using Bootstrap utilities

### **Responsive Layout**
```html
<!-- KPI Cards -->
<div class="col-md-3 col-sm-6 mb-3"> <!-- 4 cards on desktop, 2 on tablet, 1 on mobile -->

<!-- Charts -->
<div class="col-lg-6 mb-4"> <!-- 2 charts per row on desktop, stacked on mobile -->

<!-- System Metrics -->
<div class="col-lg-8"> <!-- Chart takes 8/12 columns -->
<div class="col-lg-4"> <!-- Metrics take 4/12 columns -->
```

### **Status Badges**
```erb
<% if hit_rate >= 90 %>
  <span class="badge bg-success">Excellent</span>
<% elsif hit_rate >= 75 %>
  <span class="badge bg-warning">Good</span>
<% else %>
  <span class="badge bg-danger">Needs Improvement</span>
<% end %>
```

## 🔧 **Implementation Guide**

### **Step 1: Controller Implementation**
```ruby
def performance
  authorize @resource
  
  days = params[:days]&.to_i || 30
  period_start = days.days.ago
  
  @performance_data = {
    resource: { id: @resource.id, name: @resource.name },
    period: {
      days: days,
      start_date: period_start.strftime('%Y-%m-%d'),
      end_date: Date.current.strftime('%Y-%m-%d')
    },
    cache_performance: collect_cache_performance_data,
    database_performance: collect_database_performance_data,
    response_times: collect_response_time_data,
    user_activity: collect_user_activity_data(days),
    system_metrics: collect_system_metrics_data
  }
  
  respond_to do |format|
    format.html
    format.json { render json: @performance_data }
  end
end
```

### **Step 2: Data Collection Methods**
```ruby
private

def collect_cache_performance_data
  cache_stats = AdvancedCacheService.cache_stats
  {
    hit_rate: cache_stats[:hit_rate] || 0,
    total_hits: cache_stats[:hits] || 0,
    total_misses: cache_stats[:misses] || 0,
    total_operations: cache_stats[:total_operations] || 0,
    last_reset: cache_stats[:last_reset]
  }
rescue => e
  Rails.logger.error("Cache performance data collection failed: #{e.message}")
  { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
end
```

### **Step 3: View Implementation**
```erb
<% content_for :title, "#{@resource.name} - Performance Dashboard" %>

<%= render 'shared/performance_dashboard', 
    title: "Resource Performance Dashboard", 
    subtitle: @resource.name,
    performance_data: @performance_data,
    base_path: resource_performance_path(@resource),
    icon: "fas fa-chart-line" %>
```

## 📈 **Performance Data Structure**

### **Expected Data Format**
```ruby
{
  resource: {
    id: 1,
    name: "Resource Name",
    created_at: "2024-01-01T00:00:00Z"
  },
  period: {
    days: 30,
    start_date: "2024-01-01",
    end_date: "2024-01-31"
  },
  cache_performance: {
    hit_rate: 85.5,
    total_hits: 1250,
    total_misses: 200,
    total_operations: 1450,
    last_reset: "2024-01-01T00:00:00Z"
  },
  database_performance: {
    primary_queries: 500,
    replica_queries: 1200,
    replica_lag: 50,
    connection_pool_usage: 65.2,
    slow_queries: 5
  },
  response_times: {
    average: 0.245,
    maximum: 1.2,
    request_count: 1500,
    cache_efficiency: 12.5
  },
  user_activity: {
    total_sessions: 450,
    unique_visitors: 320,
    page_views: 1800,
    average_session_duration: 180,
    bounce_rate: 25.5
  },
  system_metrics: {
    memory_usage: 512,
    cpu_usage: 45.2,
    disk_usage: 78.1,
    active_connections: 15,
    background_jobs: 3
  }
}
```

## 🚀 **Usage Examples**

### **Restaurant Performance**
```erb
<%= render 'shared/performance_dashboard', 
    title: "Restaurant Performance Dashboard", 
    subtitle: @restaurant.name,
    performance_data: @performance_data,
    base_path: performance_restaurant_path(@restaurant),
    icon: "fas fa-store" %>
```

### **Menu Performance**
```erb
<%= render 'shared/performance_dashboard', 
    title: "Menu Performance Dashboard", 
    subtitle: "#{@menu.name} (#{@restaurant.name})",
    performance_data: @performance_data,
    base_path: performance_restaurant_menu_path(@restaurant, @menu),
    icon: "fas fa-utensils" %>
```

### **Admin Performance**
```erb
<%= render 'shared/performance_dashboard', 
    title: "System Performance Dashboard", 
    subtitle: "Administrative Overview",
    performance_data: @performance_data,
    base_path: admin_performance_path,
    icon: "fas fa-server",
    show_period_selector: false %>
```

## 🔍 **Customization Options**

### **Component Configuration**
```erb
<%= render 'shared/performance_dashboard', 
    title: "Custom Dashboard",
    subtitle: "Custom Subtitle",
    performance_data: @data,
    base_path: custom_path,
    icon: "fas fa-custom-icon",
    show_period_selector: true,  # Show 7/30/90 day buttons
    show_kpis: true,            # Show KPI cards
    show_charts: true,          # Show chart section
    show_details_table: true    # Show details table
%>
```

### **Chart Customization**
The Chart.js configuration can be customized by modifying `_performance_charts_script.html.erb`:

```javascript
// Custom chart options
const customOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'top', // Change legend position
      labels: {
        padding: 20,
        usePointStyle: true,
        font: {
          size: 14 // Custom font size
        }
      }
    }
  }
};
```

## 📱 **Mobile Responsiveness**

### **Breakpoint Behavior**
- **Desktop (lg+)**: 2 charts per row, full table display
- **Tablet (md)**: 2 KPI cards per row, stacked charts
- **Mobile (sm)**: 1 KPI card per row, stacked charts, horizontal scroll table

### **Touch Interactions**
- **Chart.js**: Native touch support for zooming and panning
- **Tables**: Horizontal scroll on mobile devices
- **Buttons**: Touch-friendly sizing and spacing

## 🎯 **Performance Considerations**

### **Chart.js Optimization**
- **CDN Loading**: Chart.js loaded from CDN for caching benefits
- **Lazy Loading**: Charts only initialize when DOM is ready
- **Memory Management**: Proper chart destruction on page navigation
- **Data Validation**: Safe data access with fallback values

### **Caching Strategy**
- **Component Caching**: Reusable components reduce rendering time
- **Data Caching**: Performance data cached at controller level
- **Asset Optimization**: CSS/JS assets optimized for production

## 🔧 **Maintenance & Updates**

### **Adding New Chart Types**
1. Add chart container to `_performance_charts.html.erb`
2. Add chart initialization to `_performance_charts_script.html.erb`
3. Update data structure documentation
4. Test across all performance endpoints

### **Styling Updates**
1. Modify Bootstrap classes in component files
2. Update Chart.js color schemes in script file
3. Test responsive behavior across devices
4. Validate accessibility compliance

### **Performance Monitoring**
- Monitor Chart.js loading times
- Track component rendering performance
- Validate data collection efficiency
- Monitor mobile performance metrics

## 🎉 **Benefits**

### **Developer Experience**
- **Consistent Implementation**: Same approach across all performance endpoints
- **Rapid Development**: New performance pages in minutes, not hours
- **Maintainable Code**: Centralized components reduce duplication
- **Type Safety**: Consistent data structures across endpoints

### **User Experience**
- **Consistent Interface**: Same look and feel across all performance pages
- **Responsive Design**: Works perfectly on all devices
- **Interactive Charts**: Rich, interactive visualizations
- **Performance Insights**: Clear, actionable performance data

### **Business Value**
- **Performance Monitoring**: Real-time insights into system performance
- **Data-Driven Decisions**: Clear metrics for optimization priorities
- **Scalable Architecture**: Easy to add new performance endpoints
- **Professional Appearance**: Enterprise-grade performance dashboards

This performance visualization system provides a solid foundation for monitoring and optimizing the Smart Menu application's performance across all levels of the system architecture.

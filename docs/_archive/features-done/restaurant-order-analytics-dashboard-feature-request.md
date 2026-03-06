# Restaurant Order Analytics Dashboard Feature Request

## 📋 **Feature Overview**

**Feature Name**: Comprehensive Restaurant Order Analytics Dashboard
**Priority**: High
**Category**: Business Intelligence & Analytics
**Estimated Effort**: Large (10-14 weeks)
**Target Release**: Q2 2026

## 🎯 **User Story**

**As a** restaurant manager
**I want to** visualize detailed analytics on orders being processed in the restaurant
**So that** I can understand menu performance, time patterns, order flow, and optimize restaurant operations

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Order Processing Analytics**
- **Order Volume Tracking**: Real-time and historical order counts
- **Order State Flow**: Visualize order progression through states
- **Dwell Time Analysis**: Time spent in each order state (pending, confirmed, preparing, ready, delivered)
- **Order Completion Metrics**: Success rates, cancellation rates, fulfillment times
- **Peak Period Identification**: Busiest hours, days, and seasonal patterns

#### **2. Menu Performance Analytics**
- **Menu-Level Analysis**: Performance metrics by menu
- **Item Popularity**: Most/least ordered items with trend analysis
- **Menu Contribution**: Revenue and order volume by menu
- **Cross-Menu Comparison**: Performance comparison across different menus
- **Menu Lifecycle Tracking**: Performance changes over time

#### **3. Time-Based Analytics**
- **Hourly Patterns**: Order distribution throughout the day
- **Daily Trends**: Day-of-week performance patterns
- **Seasonal Analysis**: Monthly and seasonal ordering trends
- **Peak vs. Off-Peak**: Comparative analysis of busy and slow periods
- **Time-to-Completion**: Average preparation and delivery times by time period

#### **4. Order Item Deep Dive**
- **Item Performance Metrics**: Sales volume, revenue, popularity rankings
- **Category Analysis**: Performance by menu categories
- **Price Point Analysis**: Order patterns by price ranges
- **Combination Analysis**: Frequently ordered item combinations
- **Inventory Impact**: Item performance vs. inventory levels

### **Secondary Requirements**

#### **5. Order Curation Analytics**
- **Order Size Distribution**: Min, max, average order values and item counts
- **Customer Behavior**: Order patterns and preferences
- **Customization Analysis**: Most requested modifications and add-ons
- **Order Complexity**: Analysis of simple vs. complex orders
- **Repeat Order Patterns**: Frequency and consistency of orders

#### **6. Advanced Visualization**
- **Interactive Dashboards**: Drill-down capabilities and filtering
- **Real-Time Monitoring**: Live order flow and status updates
- **Comparative Views**: Side-by-side analysis of different periods
- **Export Capabilities**: PDF reports and data export functionality
- **Mobile Optimization**: Responsive design for tablet and mobile access

## 🔧 **Technical Specifications**

### **Database Schema**

```sql
-- Order analytics aggregation table
CREATE TABLE order_analytics (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  menu_id BIGINT,
  date DATE NOT NULL,
  hour_of_day INTEGER NOT NULL, -- 0-23
  day_of_week INTEGER NOT NULL, -- 0=Sunday, 6=Saturday
  total_orders INTEGER DEFAULT 0,
  completed_orders INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  average_order_value DECIMAL(10,2) DEFAULT 0,
  min_order_value DECIMAL(10,2),
  max_order_value DECIMAL(10,2),
  average_items_per_order DECIMAL(8,2) DEFAULT 0,
  average_preparation_time_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  FOREIGN KEY (menu_id) REFERENCES menus(id),
  INDEX idx_restaurant_date (restaurant_id, date),
  INDEX idx_menu_date (menu_id, date),
  INDEX idx_time_patterns (day_of_week, hour_of_day),
  UNIQUE KEY unique_analytics_record (restaurant_id, menu_id, date, hour_of_day)
);

-- Order state tracking for dwell time analysis
CREATE TABLE order_state_transitions (
  id BIGINT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  from_state VARCHAR(50),
  to_state VARCHAR(50) NOT NULL,
  transition_time TIMESTAMP NOT NULL,
  duration_seconds INTEGER,
  triggered_by_user_id BIGINT,
  notes TEXT,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (triggered_by_user_id) REFERENCES users(id),
  INDEX idx_order_id (order_id),
  INDEX idx_transition_time (transition_time),
  INDEX idx_states (from_state, to_state)
);

-- Menu item performance analytics
CREATE TABLE menu_item_analytics (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  menu_id BIGINT NOT NULL,
  menu_item_id BIGINT NOT NULL,
  date DATE NOT NULL,
  hour_of_day INTEGER NOT NULL,
  order_count INTEGER DEFAULT 0,
  quantity_sold INTEGER DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  average_price DECIMAL(8,2) DEFAULT 0,
  popularity_rank INTEGER,
  revenue_rank INTEGER,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  FOREIGN KEY (menu_id) REFERENCES menus(id),
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
  INDEX idx_restaurant_date (restaurant_id, date),
  INDEX idx_menu_item_date (menu_item_id, date),
  INDEX idx_performance_ranks (popularity_rank, revenue_rank),
  UNIQUE KEY unique_item_analytics (menu_item_id, date, hour_of_day)
);

-- Order curation patterns
CREATE TABLE order_curation_analytics (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  date DATE NOT NULL,
  order_size_category VARCHAR(20) NOT NULL, -- 'small', 'medium', 'large', 'extra_large'
  min_items INTEGER NOT NULL,
  max_items INTEGER NOT NULL,
  order_count INTEGER DEFAULT 0,
  total_value DECIMAL(12,2) DEFAULT 0,
  average_value DECIMAL(10,2) DEFAULT 0,
  average_preparation_time INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_restaurant_date (restaurant_id, date),
  INDEX idx_size_category (order_size_category),
  UNIQUE KEY unique_curation_record (restaurant_id, date, order_size_category)
);
```

### **Backend Implementation**

```ruby
class OrderAnalyticsService
  def initialize(restaurant, date_range = 30.days.ago..Date.current)
    @restaurant = restaurant
    @date_range = date_range
  end

  def generate_comprehensive_report
    {
      order_processing: order_processing_analytics,
      menu_performance: menu_performance_analytics,
      time_based: time_based_analytics,
      item_analysis: order_item_analytics,
      curation_metrics: order_curation_analytics,
      dwell_time: order_state_dwell_analysis
    }
  end

  def order_processing_analytics
    orders = @restaurant.orders.where(created_at: @date_range)

    {
      total_orders: orders.count,
      completed_orders: orders.completed.count,
      cancelled_orders: orders.cancelled.count,
      completion_rate: calculate_completion_rate(orders),
      average_fulfillment_time: calculate_average_fulfillment_time(orders),
      peak_hours: identify_peak_hours(orders),
      daily_trends: calculate_daily_trends(orders)
    }
  end

  def menu_performance_analytics
    menu_data = {}

    @restaurant.menus.each do |menu|
      orders = menu.orders.where(created_at: @date_range)

      menu_data[menu.id] = {
        menu_name: menu.name,
        total_orders: orders.count,
        total_revenue: orders.sum(:total_amount),
        average_order_value: orders.average(:total_amount)&.round(2),
        most_popular_items: get_popular_items(menu, 5),
        revenue_contribution: calculate_revenue_contribution(menu, orders)
      }
    end

    menu_data
  end

  def time_based_analytics
    hourly_data = generate_hourly_breakdown
    daily_data = generate_daily_breakdown

    {
      hourly_patterns: hourly_data,
      daily_patterns: daily_data,
      peak_periods: identify_peak_periods(hourly_data),
      seasonal_trends: calculate_seasonal_trends
    }
  end

  def order_item_analytics
    items_data = {}

    @restaurant.menu_items.includes(:order_items).each do |item|
      order_items = item.order_items.joins(:order)
                       .where(orders: { created_at: @date_range })

      items_data[item.id] = {
        item_name: item.name,
        category: item.menu_section&.name,
        total_quantity: order_items.sum(:quantity),
        total_orders: order_items.count,
        total_revenue: order_items.sum('quantity * price'),
        average_price: order_items.average(:price)&.round(2),
        popularity_rank: calculate_popularity_rank(item),
        time_distribution: calculate_item_time_distribution(order_items)
      }
    end

    items_data.sort_by { |_, data| -data[:total_quantity] }.to_h
  end

  def order_curation_analytics
    orders = @restaurant.orders.where(created_at: @date_range)

    curation_data = {
      order_size_distribution: calculate_order_size_distribution(orders),
      value_distribution: calculate_order_value_distribution(orders),
      complexity_analysis: analyze_order_complexity(orders),
      min_max_averages: {
        min_order_value: orders.minimum(:total_amount),
        max_order_value: orders.maximum(:total_amount),
        average_order_value: orders.average(:total_amount)&.round(2),
        min_items_per_order: calculate_min_items_per_order(orders),
        max_items_per_order: calculate_max_items_per_order(orders),
        average_items_per_order: calculate_average_items_per_order(orders)
      }
    }

    curation_data
  end

  def order_state_dwell_analysis
    transitions = OrderStateTransition.joins(:order)
                                    .where(orders: { restaurant_id: @restaurant.id })
                                    .where(transition_time: @date_range)

    dwell_times = {}

    %w[pending confirmed preparing ready delivered].each do |state|
      state_transitions = transitions.where(to_state: state)

      dwell_times[state] = {
        average_duration: calculate_average_dwell_time(state_transitions),
        min_duration: state_transitions.minimum(:duration_seconds),
        max_duration: state_transitions.maximum(:duration_seconds),
        total_orders: state_transitions.count
      }
    end

    dwell_times
  end

  private

  def generate_hourly_breakdown
    hourly_data = {}

    (0..23).each do |hour|
      orders = @restaurant.orders.where(created_at: @date_range)
                         .where('EXTRACT(hour FROM created_at) = ?', hour)

      hourly_data[hour] = {
        order_count: orders.count,
        total_revenue: orders.sum(:total_amount),
        average_order_value: orders.average(:total_amount)&.round(2) || 0
      }
    end

    hourly_data
  end

  def calculate_order_size_distribution(orders)
    distribution = { small: 0, medium: 0, large: 0, extra_large: 0 }

    orders.includes(:order_items).each do |order|
      item_count = order.order_items.sum(:quantity)

      category = case item_count
                when 1..2 then :small
                when 3..5 then :medium
                when 6..10 then :large
                else :extra_large
                end

      distribution[category] += 1
    end

    distribution
  end
end

class OrderAnalyticsDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    @date_range = parse_date_range(params[:date_range])
    @analytics_service = OrderAnalyticsService.new(@restaurant, @date_range)
    @analytics_data = @analytics_service.generate_comprehensive_report

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  def export
    @analytics_service = OrderAnalyticsService.new(@restaurant, parse_date_range(params[:date_range]))
    @analytics_data = @analytics_service.generate_comprehensive_report

    respond_to do |format|
      format.pdf do
        render pdf: "order_analytics_#{@restaurant.name}_#{Date.current}",
               template: 'order_analytics/export_pdf'
      end
      format.csv do
        send_data generate_csv_export(@analytics_data),
                  filename: "order_analytics_#{@restaurant.name}_#{Date.current}.csv"
      end
    end
  end

  private

  def parse_date_range(range_param)
    case range_param
    when '7_days' then 7.days.ago..Date.current
    when '30_days' then 30.days.ago..Date.current
    when '90_days' then 90.days.ago..Date.current
    when '1_year' then 1.year.ago..Date.current
    else 30.days.ago..Date.current
    end
  end
end
```

### **Frontend Implementation**

```html
<!-- Order Analytics Dashboard -->
<div class="analytics-dashboard">
  <div class="dashboard-header">
    <h1>Order Analytics Dashboard</h1>
    <div class="date-range-controls">
      <select id="date-range-selector" onchange="updateDateRange()">
        <option value="7_days">Last 7 Days</option>
        <option value="30_days" selected>Last 30 Days</option>
        <option value="90_days">Last 90 Days</option>
        <option value="1_year">Last Year</option>
      </select>
      <button class="btn-export" onclick="exportReport()">Export Report</button>
    </div>
  </div>

  <!-- Key Metrics Overview -->
  <div class="metrics-overview">
    <div class="metric-card">
      <h3>Total Orders</h3>
      <div class="metric-value"><%= @analytics_data[:order_processing][:total_orders] %></div>
      <div class="metric-change">+12% vs last period</div>
    </div>

    <div class="metric-card">
      <h3>Completion Rate</h3>
      <div class="metric-value"><%= @analytics_data[:order_processing][:completion_rate] %>%</div>
      <div class="metric-change">+2.3% vs last period</div>
    </div>

    <div class="metric-card">
      <h3>Avg Order Value</h3>
      <div class="metric-value">$<%= @analytics_data[:curation_metrics][:min_max_averages][:average_order_value] %></div>
      <div class="metric-change">+$3.20 vs last period</div>
    </div>

    <div class="metric-card">
      <h3>Avg Fulfillment Time</h3>
      <div class="metric-value"><%= @analytics_data[:order_processing][:average_fulfillment_time] %> min</div>
      <div class="metric-change">-2 min vs last period</div>
    </div>
  </div>

  <!-- Order Flow Visualization -->
  <div class="analytics-section">
    <h2>Order State Flow Analysis</h2>
    <div class="chart-container">
      <canvas id="order-flow-chart"></canvas>
    </div>

    <div class="dwell-time-table">
      <h3>Average Dwell Time by State</h3>
      <table class="analytics-table">
        <thead>
          <tr>
            <th>Order State</th>
            <th>Avg Duration</th>
            <th>Min Duration</th>
            <th>Max Duration</th>
            <th>Total Orders</th>
          </tr>
        </thead>
        <tbody>
          <% @analytics_data[:dwell_time].each do |state, data| %>
            <tr>
              <td><%= state.humanize %></td>
              <td><%= format_duration(data[:average_duration]) %></td>
              <td><%= format_duration(data[:min_duration]) %></td>
              <td><%= format_duration(data[:max_duration]) %></td>
              <td><%= data[:total_orders] %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Time-Based Analytics -->
  <div class="analytics-section">
    <h2>Time-Based Order Patterns</h2>

    <div class="time-charts-grid">
      <div class="chart-container">
        <h3>Hourly Order Distribution</h3>
        <canvas id="hourly-orders-chart"></canvas>
      </div>

      <div class="chart-container">
        <h3>Daily Order Trends</h3>
        <canvas id="daily-trends-chart"></canvas>
      </div>
    </div>

    <div class="peak-periods-summary">
      <h3>Peak Periods Identified</h3>
      <div class="peak-periods-list">
        <% @analytics_data[:time_based][:peak_periods].each do |period| %>
          <div class="peak-period-item">
            <span class="period-time"><%= period[:time_range] %></span>
            <span class="period-volume"><%= period[:order_count] %> orders</span>
            <span class="period-revenue">$<%= period[:revenue] %></span>
          </div>
        <% end %>
      </div>
    </div>
  </div>

  <!-- Menu Performance Analysis -->
  <div class="analytics-section">
    <h2>Menu Performance Analysis</h2>

    <div class="menu-performance-grid">
      <% @analytics_data[:menu_performance].each do |menu_id, data| %>
        <div class="menu-card">
          <h3><%= data[:menu_name] %></h3>

          <div class="menu-metrics">
            <div class="menu-metric">
              <span class="label">Total Orders:</span>
              <span class="value"><%= data[:total_orders] %></span>
            </div>
            <div class="menu-metric">
              <span class="label">Revenue:</span>
              <span class="value">$<%= data[:total_revenue] %></span>
            </div>
            <div class="menu-metric">
              <span class="label">Avg Order Value:</span>
              <span class="value">$<%= data[:average_order_value] %></span>
            </div>
            <div class="menu-metric">
              <span class="label">Revenue Share:</span>
              <span class="value"><%= data[:revenue_contribution] %>%</span>
            </div>
          </div>

          <div class="popular-items">
            <h4>Top Items</h4>
            <% data[:most_popular_items].each do |item| %>
              <div class="popular-item">
                <span class="item-name"><%= item[:name] %></span>
                <span class="item-count"><%= item[:quantity] %> sold</span>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
  </div>

  <!-- Order Item Deep Dive -->
  <div class="analytics-section">
    <h2>Order Item Performance</h2>

    <div class="item-analytics-controls">
      <select id="sort-by-selector" onchange="sortItemAnalytics()">
        <option value="quantity">Sort by Quantity Sold</option>
        <option value="revenue">Sort by Revenue</option>
        <option value="popularity">Sort by Popularity</option>
      </select>

      <input type="text" id="item-search" placeholder="Search items..." onkeyup="filterItems()">
    </div>

    <div class="item-analytics-table">
      <table class="analytics-table" id="items-table">
        <thead>
          <tr>
            <th>Item Name</th>
            <th>Category</th>
            <th>Quantity Sold</th>
            <th>Total Orders</th>
            <th>Revenue</th>
            <th>Avg Price</th>
            <th>Popularity Rank</th>
          </tr>
        </thead>
        <tbody>
          <% @analytics_data[:item_analysis].each do |item_id, data| %>
            <tr>
              <td><%= data[:item_name] %></td>
              <td><%= data[:category] %></td>
              <td><%= data[:total_quantity] %></td>
              <td><%= data[:total_orders] %></td>
              <td>$<%= data[:total_revenue] %></td>
              <td>$<%= data[:average_price] %></td>
              <td>#<%= data[:popularity_rank] %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Order Curation Analytics -->
  <div class="analytics-section">
    <h2>Order Curation Analysis</h2>

    <div class="curation-metrics-grid">
      <div class="curation-card">
        <h3>Order Value Distribution</h3>
        <div class="value-stats">
          <div class="stat">
            <span class="label">Minimum:</span>
            <span class="value">$<%= @analytics_data[:curation_metrics][:min_max_averages][:min_order_value] %></span>
          </div>
          <div class="stat">
            <span class="label">Maximum:</span>
            <span class="value">$<%= @analytics_data[:curation_metrics][:min_max_averages][:max_order_value] %></span>
          </div>
          <div class="stat">
            <span class="label">Average:</span>
            <span class="value">$<%= @analytics_data[:curation_metrics][:min_max_averages][:average_order_value] %></span>
          </div>
        </div>
      </div>

      <div class="curation-card">
        <h3>Items per Order</h3>
        <div class="items-stats">
          <div class="stat">
            <span class="label">Minimum:</span>
            <span class="value"><%= @analytics_data[:curation_metrics][:min_max_averages][:min_items_per_order] %></span>
          </div>
          <div class="stat">
            <span class="label">Maximum:</span>
            <span class="value"><%= @analytics_data[:curation_metrics][:min_max_averages][:max_items_per_order] %></span>
          </div>
          <div class="stat">
            <span class="label">Average:</span>
            <span class="value"><%= @analytics_data[:curation_metrics][:min_max_averages][:average_items_per_order] %></span>
          </div>
        </div>
      </div>

      <div class="curation-card">
        <h3>Order Size Distribution</h3>
        <canvas id="order-size-chart"></canvas>
      </div>
    </div>
  </div>
</div>
```

## 📊 **Success Metrics**

### **1. Business Intelligence**
- Improved decision-making speed and accuracy
- Identification of revenue optimization opportunities
- Better understanding of customer ordering patterns
- Enhanced menu performance insights

### **2. Operational Efficiency**
- Reduced time to identify operational bottlenecks
- Improved staff scheduling based on peak period data
- Better inventory management through item analytics
- Enhanced customer satisfaction through faster service

### **3. Revenue Impact**
- Increased revenue through data-driven menu optimization
- Improved profit margins through better pricing strategies
- Enhanced customer retention through service improvements
- Better resource allocation based on analytics insights

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Analytics (Weeks 1-4)**
- Database schema and data collection
- Basic order processing analytics
- Simple dashboard interface
- Time-based analysis

### **Phase 2: Advanced Analytics (Weeks 5-8)**
- Menu and item performance analytics
- Order state dwell time analysis
- Advanced visualization components
- Export functionality

### **Phase 3: Enhanced Features (Weeks 9-12)**
- Real-time analytics updates
- Predictive analytics capabilities
- Mobile optimization
- Advanced filtering and drill-down

### **Phase 4: Intelligence Layer (Weeks 13-14)**
- Machine learning insights
- Automated recommendations
- Comparative analysis tools
- Integration with other systems

## 🎯 **Acceptance Criteria**

### **Must Have**
- ✅ Comprehensive order processing analytics
- ✅ Menu and item performance tracking
- ✅ Time-based pattern analysis
- ✅ Order state dwell time measurement
- ✅ Min/max/average order curation metrics
- ✅ Interactive dashboard with filtering

### **Should Have**
- ✅ Real-time analytics updates
- ✅ Export capabilities (PDF, CSV)
- ✅ Mobile-responsive design
- ✅ Advanced visualization charts
- ✅ Comparative analysis tools

### **Could Have**
- ✅ Predictive analytics
- ✅ Machine learning insights
- ✅ Automated recommendations
- ✅ Integration with external systems

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

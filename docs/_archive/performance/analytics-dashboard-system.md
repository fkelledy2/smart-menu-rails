# 📊 Analytics Dashboard System

## Overview
The Analytics Dashboard provides comprehensive business intelligence for restaurant owners, featuring real-time charts, key metrics, and data-driven insights using Chart.js and Bootstrap styling.

## 🎯 Features Implemented

### **Key Metrics Cards**
- **Total Orders**: Complete order count with status breakdown
- **Total Revenue**: Revenue tracking with average order value
- **Customer Analytics**: Total, new, and returning customer counts
- **Growth Rate**: Period-over-period growth comparison

### **Interactive Charts**
- **Daily Orders**: Line chart showing order trends over time
- **Daily Revenue**: Bar chart displaying revenue patterns
- **Daily Customers**: Line chart tracking customer acquisition
- **Peak Hours**: Bar chart showing busiest times of day
- **Order Status**: Doughnut chart with completion rates

### **Data Tables**
- **Top Selling Items**: Best performing menu items by quantity
- **Order Status Breakdown**: Visual representation of order states

### **Traffic Analytics**
- **Page Views**: Website traffic metrics
- **Unique Visitors**: Visitor tracking
- **Bounce Rate**: User engagement metrics

## 🏗️ Architecture

### **Controller Structure**
```ruby
# GET /restaurants/:id/analytics
def analytics
  # Data collection with error handling
  @analytics_data = {
    restaurant: { id, name, created_at },
    period: { days, start_date, end_date },
    orders: collect_order_analytics_data(days),
    revenue: collect_revenue_analytics_data(days),
    customers: collect_customer_analytics_data(days),
    menu_items: collect_menu_item_analytics_data(days),
    traffic: collect_traffic_analytics_data(days),
    trends: collect_trend_analytics_data(days)
  }
end
```

### **Data Collection Methods**

#### **Order Analytics**
```ruby
def collect_order_analytics_data(days)
  {
    total: orders.count,
    completed: orders.where(status: 'completed').count,
    cancelled: orders.where(status: 'cancelled').count,
    pending: orders.where(status: 'pending').count,
    daily_data: generate_daily_order_data(orders, days)
  }
end
```

#### **Revenue Analytics**
```ruby
def collect_revenue_analytics_data(days)
  {
    total: total_revenue,
    average_order: average_order_value,
    daily_data: generate_daily_revenue_data(orders, days),
    top_items: get_top_selling_items(days)
  }
end
```

#### **Customer Analytics**
```ruby
def collect_customer_analytics_data(days)
  {
    total: total_customers,
    new: new_customers,
    returning: returning_customers,
    daily_data: generate_daily_customer_data(orders, days)
  }
end
```

## 🎨 UI Components

### **Shared Dashboard Component**
```erb
<%= render 'shared/analytics_dashboard', 
    title: "Restaurant Analytics Dashboard", 
    subtitle: @analytics_data[:restaurant][:name],
    analytics_data: @analytics_data,
    base_path: analytics_restaurant_path(@restaurant),
    icon: "fas fa-chart-line" %>
```

### **Period Selector**
- 7 Days, 30 Days, 90 Days buttons
- Dynamic URL generation with query parameters
- Active state styling

### **Responsive Design**
- Bootstrap 5 grid system
- Mobile-friendly charts
- Collapsible sections on smaller screens

## 📈 Chart Configuration

### **Chart.js Integration**
```javascript
// CDN inclusion
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

// Chart configuration
Chart.defaults.responsive = true;
Chart.defaults.maintainAspectRatio = false;
```

### **Chart Types Used**
- **Line Charts**: Orders and customers over time
- **Bar Charts**: Revenue and peak hours
- **Doughnut Chart**: Order status breakdown

### **Color Scheme**
- Primary: `rgb(54, 162, 235)` (Blue)
- Success: `rgb(40, 167, 69)` (Green) 
- Info: `rgb(23, 162, 184)` (Cyan)
- Warning: `rgb(255, 193, 7)` (Yellow)
- Danger: `rgb(220, 53, 69)` (Red)

## 🔧 Technical Implementation

### **Route Configuration**
```ruby
# In config/routes.rb
resources :restaurants do
  member do
    get :analytics  # /restaurants/:id/analytics
    get :performance
  end
end
```

### **Data Model Corrections Applied**
- **Order Status**: Uses enum values (`closed` instead of `completed`)
- **Revenue Field**: Uses `gross` instead of `total` for order amounts
- **Menu Items**: Accessed via `restaurant.menus.joins(:menuitems)` relationship
- **Customer Tracking**: Handles nil emails gracefully with fallback logic

### **Authorization**
```ruby
# Pundit authorization
authorize @restaurant
```

### **Error Handling**
```ruby
rescue => e
  Rails.logger.error "[RestaurantsController#analytics] Error: #{e.message}"
  # Provide fallback data structure
end
```

### **JSON API Support**
```ruby
respond_to do |format|
  format.html
  format.json { render json: @analytics_data }
end
```

## 📊 Data Sources

### **Order Data**
- `@restaurant.ordrs` - Main order records
- Status tracking: completed, pending, cancelled
- Date range filtering for period analysis

### **Revenue Data**
- Order totals and averages
- Daily revenue aggregation
- Top-selling item analysis via `Ordritem` joins

### **Customer Data**
- Email-based customer identification
- New vs returning customer logic
- Daily customer acquisition tracking

### **Menu Item Data**
- `Ordritem.joins(:ordr, :menuitem)` for sales data
- Popularity ranking by quantity sold
- Restaurant-scoped menu item analysis

## 🚀 Usage Examples

### **Basic Analytics View**
```erb
<%= render 'shared/analytics_dashboard', 
    title: "Restaurant Analytics Dashboard", 
    subtitle: @restaurant.name,
    analytics_data: @analytics_data,
    base_path: analytics_restaurant_path(@restaurant),
    icon: "fas fa-chart-line" %>
```

### **Custom Period**
```
/restaurants/1/analytics?days=7   # 7-day view
/restaurants/1/analytics?days=30  # 30-day view (default)
/restaurants/1/analytics?days=90  # 90-day view
```

### **JSON API Access**
```
GET /restaurants/1/analytics.json
```

## 🎯 Key Benefits

### **Business Intelligence**
- **Revenue Tracking**: Monitor daily revenue and trends
- **Customer Insights**: Track acquisition and retention
- **Operational Analytics**: Identify peak hours and patterns
- **Menu Performance**: Understand item popularity

### **User Experience**
- **Interactive Charts**: Hover effects and tooltips
- **Responsive Design**: Works on all devices
- **Period Selection**: Flexible time range analysis
- **Real-time Data**: Up-to-date business metrics

### **Technical Benefits**
- **Modular Design**: Reusable dashboard component
- **Error Resilience**: Graceful fallback for missing data
- **Performance Optimized**: Efficient database queries
- **Extensible**: Easy to add new metrics and charts

## 🔮 Future Enhancements

### **Advanced Analytics**
- Predictive analytics and forecasting
- Seasonal trend analysis
- Customer segmentation
- Inventory correlation analysis

### **Integration Opportunities**
- Google Analytics integration
- Social media metrics
- Email marketing analytics
- POS system integration

### **Export Features**
- PDF report generation
- CSV data export
- Scheduled email reports
- Dashboard sharing

The Analytics Dashboard provides restaurant owners with powerful insights to make data-driven decisions and optimize their business performance.

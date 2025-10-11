# Menu Item Profit Margin Tracking Feature Request

## 📋 **Feature Overview**

**Feature Name**: Menu Item Profit Margin Tracking and Reporting
**Priority**: High
**Category**: Financial Management & Analytics
**Estimated Effort**: Large (8-10 weeks)
**Target Release**: Q2 2026

## 🎯 **User Story**

**As a** restaurant manager
**I want to** track the cost of production and profit margin for each menu item
**So that** I can make data-driven pricing decisions and optimize menu profitability

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Cost Tracking System**
- **Production Cost Recording**: Track ingredient costs, labor, and overhead per item
- **Cost Breakdown**: Detailed cost components (ingredients, labor, packaging, overhead)
- **Historical Cost Tracking**: Monitor cost changes over time
- **Supplier Integration**: Link to supplier pricing for automatic cost updates
- **Recipe Costing**: Calculate costs based on recipe ingredients and quantities

#### **2. Profit Margin Calculations**
- **Real-time Calculations**: Automatic profit margin computation (Revenue - Cost)
- **Percentage and Dollar Margins**: Display both absolute and percentage margins
- **Margin Alerts**: Notifications when margins fall below thresholds
- **Target Margin Setting**: Set and track target margins per item or category
- **Dynamic Pricing Suggestions**: Recommend pricing based on desired margins

#### **3. Comprehensive Reporting**
- **Profit Margin Dashboard**: Visual overview of menu profitability
- **Item-Level Reports**: Detailed profit analysis per menu item
- **Category Analysis**: Profit margins by menu category
- **Trend Analysis**: Historical margin trends and forecasting
- **Comparative Reports**: Compare margins across items, categories, and time periods

### **Secondary Requirements**

#### **4. Cost Management Tools**
- **Ingredient Cost Database**: Centralized ingredient pricing management
- **Vendor Price Tracking**: Monitor supplier price changes
- **Waste Factor Calculations**: Account for food waste in cost calculations
- **Portion Control**: Track actual vs. theoretical portions
- **Seasonal Cost Adjustments**: Handle seasonal ingredient price variations

#### **5. Advanced Analytics**
- **Menu Engineering Matrix**: Classify items by popularity and profitability
- **ABC Analysis**: Categorize items by profit contribution
- **Price Elasticity Analysis**: Understand demand sensitivity to price changes
- **Competitive Pricing Intelligence**: Compare margins with market standards
- **Optimization Recommendations**: AI-powered menu optimization suggestions

## 🔧 **Technical Specifications**

### **Database Schema**

```sql
-- Menu item costs table
CREATE TABLE menu_item_costs (
  id BIGINT PRIMARY KEY,
  menu_item_id BIGINT NOT NULL,
  ingredient_cost DECIMAL(10,4) DEFAULT 0,
  labor_cost DECIMAL(10,4) DEFAULT 0,
  packaging_cost DECIMAL(10,4) DEFAULT 0,
  overhead_cost DECIMAL(10,4) DEFAULT 0,
  total_cost DECIMAL(10,4) GENERATED ALWAYS AS (
    ingredient_cost + labor_cost + packaging_cost + overhead_cost
  ) STORED,
  cost_date DATE NOT NULL,
  notes TEXT,
  created_by_user_id BIGINT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
  FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_menu_item_id (menu_item_id),
  INDEX idx_cost_date (cost_date)
);

-- Ingredients master table
CREATE TABLE ingredients (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100),
  unit_of_measure VARCHAR(50) NOT NULL,
  current_cost_per_unit DECIMAL(10,4),
  supplier_id BIGINT,
  last_updated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_restaurant_id (restaurant_id),
  INDEX idx_category (category)
);

-- Recipe ingredients (for cost calculation)
CREATE TABLE recipe_ingredients (
  id BIGINT PRIMARY KEY,
  menu_item_id BIGINT NOT NULL,
  ingredient_id BIGINT NOT NULL,
  quantity DECIMAL(10,4) NOT NULL,
  unit VARCHAR(50) NOT NULL,
  cost_per_unit DECIMAL(10,4),
  total_cost DECIMAL(10,4) GENERATED ALWAYS AS (
    quantity * cost_per_unit
  ) STORED,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
  UNIQUE KEY unique_menu_item_ingredient (menu_item_id, ingredient_id)
);

-- Profit margin targets
CREATE TABLE profit_margin_targets (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  menu_category_id BIGINT,
  menu_item_id BIGINT,
  target_margin_percentage DECIMAL(5,2) NOT NULL,
  minimum_margin_percentage DECIMAL(5,2),
  effective_from DATE NOT NULL,
  effective_to DATE,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  FOREIGN KEY (menu_category_id) REFERENCES menu_categories(id),
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
  INDEX idx_restaurant_id (restaurant_id),
  INDEX idx_effective_dates (effective_from, effective_to)
);
```

### **Backend Implementation**

```ruby
class MenuItem < ApplicationRecord
  has_many :menu_item_costs, dependent: :destroy
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_one :profit_margin_target, dependent: :destroy

  def current_cost
    latest_cost = menu_item_costs.order(cost_date: :desc).first
    latest_cost&.total_cost || calculate_recipe_cost
  end

  def profit_margin
    return 0 if price.nil? || current_cost.nil?
    price - current_cost
  end

  def profit_margin_percentage
    return 0 if price.nil? || price.zero? || current_cost.nil?
    ((profit_margin / price) * 100).round(2)
  end

  def margin_status
    target = profit_margin_target&.target_margin_percentage
    return 'no_target' unless target

    current_percentage = profit_margin_percentage

    if current_percentage >= target
      'above_target'
    elsif current_percentage >= (profit_margin_target&.minimum_margin_percentage || 0)
      'below_target'
    else
      'critical'
    end
  end

  private

  def calculate_recipe_cost
    recipe_ingredients.sum(&:total_cost)
  end
end

class ProfitMarginService
  def initialize(restaurant)
    @restaurant = restaurant
  end

  def calculate_menu_profitability
    menu_items = @restaurant.menu_items.includes(:menu_item_costs, :recipe_ingredients)

    {
      total_items: menu_items.count,
      profitable_items: menu_items.select { |item| item.profit_margin > 0 }.count,
      average_margin: calculate_average_margin(menu_items),
      top_performers: top_performing_items(menu_items, 10),
      underperformers: underperforming_items(menu_items, 10),
      category_breakdown: category_profitability_breakdown(menu_items)
    }
  end

  def generate_margin_report(date_range = 30.days.ago..Date.current)
    # Implementation for detailed margin reporting
  end

  def suggest_price_optimizations
    # AI-powered pricing suggestions based on margins and sales data
  end

  private

  def calculate_average_margin(items)
    margins = items.map(&:profit_margin_percentage).compact
    return 0 if margins.empty?

    (margins.sum / margins.count).round(2)
  end

  def top_performing_items(items, limit)
    items.sort_by(&:profit_margin_percentage).reverse.first(limit)
  end

  def underperforming_items(items, limit)
    items.select { |item| item.profit_margin_percentage < 20 }
         .sort_by(&:profit_margin_percentage)
         .first(limit)
  end
end
```

### **Frontend Implementation**

```html
<!-- Profit Margin Dashboard -->
<div class="profit-margin-dashboard">
  <div class="dashboard-header">
    <h2>Menu Profitability Overview</h2>
    <div class="date-range-selector">
      <select id="date-range">
        <option value="7">Last 7 days</option>
        <option value="30" selected>Last 30 days</option>
        <option value="90">Last 90 days</option>
      </select>
    </div>
  </div>

  <div class="profit-summary-cards">
    <div class="summary-card">
      <h3>Average Margin</h3>
      <div class="metric-value">32.5%</div>
      <div class="metric-change positive">+2.3%</div>
    </div>

    <div class="summary-card">
      <h3>Total Profit</h3>
      <div class="metric-value">$12,450</div>
      <div class="metric-change positive">+8.7%</div>
    </div>

    <div class="summary-card">
      <h3>Items Above Target</h3>
      <div class="metric-value">68%</div>
      <div class="metric-change negative">-3.2%</div>
    </div>
  </div>

  <div class="profit-charts">
    <div class="chart-container">
      <canvas id="margin-trend-chart"></canvas>
    </div>

    <div class="chart-container">
      <canvas id="category-margin-chart"></canvas>
    </div>
  </div>
</div>

<!-- Menu Item Cost Management -->
<div class="cost-management-form">
  <h3>Update Item Costs</h3>

  <div class="cost-breakdown">
    <div class="cost-input-group">
      <label>Ingredient Cost</label>
      <input type="number" step="0.01" name="ingredient_cost"
             value="<%= @menu_item.current_cost&.ingredient_cost %>">
    </div>

    <div class="cost-input-group">
      <label>Labor Cost</label>
      <input type="number" step="0.01" name="labor_cost"
             value="<%= @menu_item.current_cost&.labor_cost %>">
    </div>

    <div class="cost-input-group">
      <label>Packaging Cost</label>
      <input type="number" step="0.01" name="packaging_cost"
             value="<%= @menu_item.current_cost&.packaging_cost %>">
    </div>

    <div class="cost-input-group">
      <label>Overhead Cost</label>
      <input type="number" step="0.01" name="overhead_cost"
             value="<%= @menu_item.current_cost&.overhead_cost %>">
    </div>
  </div>

  <div class="profit-calculation">
    <div class="calculation-row">
      <span>Selling Price:</span>
      <span class="price-value">$<%= @menu_item.price %></span>
    </div>

    <div class="calculation-row">
      <span>Total Cost:</span>
      <span class="cost-value" id="total-cost">$0.00</span>
    </div>

    <div class="calculation-row profit-row">
      <span>Profit Margin:</span>
      <span class="margin-value" id="profit-margin">$0.00 (0%)</span>
    </div>
  </div>

  <div class="margin-status" id="margin-status">
    <!-- Dynamic margin status indicator -->
  </div>
</div>
```

### **JavaScript Implementation**

```javascript
class ProfitMarginManager {
  constructor() {
    this.initEventListeners();
    this.initCharts();
    this.calculateMargins();
  }

  initEventListeners() {
    document.querySelectorAll('.cost-input-group input').forEach(input => {
      input.addEventListener('input', this.calculateMargins.bind(this));
    });
  }

  calculateMargins() {
    const ingredientCost = parseFloat(document.querySelector('[name="ingredient_cost"]').value) || 0;
    const laborCost = parseFloat(document.querySelector('[name="labor_cost"]').value) || 0;
    const packagingCost = parseFloat(document.querySelector('[name="packaging_cost"]').value) || 0;
    const overheadCost = parseFloat(document.querySelector('[name="overhead_cost"]').value) || 0;

    const totalCost = ingredientCost + laborCost + packagingCost + overheadCost;
    const sellingPrice = parseFloat(document.querySelector('.price-value').textContent.replace('$', ''));

    const profitMargin = sellingPrice - totalCost;
    const marginPercentage = sellingPrice > 0 ? (profitMargin / sellingPrice) * 100 : 0;

    this.updateDisplay(totalCost, profitMargin, marginPercentage);
    this.updateMarginStatus(marginPercentage);
  }

  updateDisplay(totalCost, profitMargin, marginPercentage) {
    document.getElementById('total-cost').textContent = `$${totalCost.toFixed(2)}`;
    document.getElementById('profit-margin').textContent =
      `$${profitMargin.toFixed(2)} (${marginPercentage.toFixed(1)}%)`;
  }

  updateMarginStatus(percentage) {
    const statusElement = document.getElementById('margin-status');
    const targetMargin = 30; // Example target

    let statusClass, statusText;

    if (percentage >= targetMargin) {
      statusClass = 'status-good';
      statusText = 'Above Target';
    } else if (percentage >= 15) {
      statusClass = 'status-warning';
      statusText = 'Below Target';
    } else {
      statusClass = 'status-critical';
      statusText = 'Critical Margin';
    }

    statusElement.className = `margin-status ${statusClass}`;
    statusElement.textContent = statusText;
  }

  initCharts() {
    this.initMarginTrendChart();
    this.initCategoryMarginChart();
  }

  initMarginTrendChart() {
    const ctx = document.getElementById('margin-trend-chart').getContext('2d');

    new Chart(ctx, {
      type: 'line',
      data: {
        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        datasets: [{
          label: 'Average Margin %',
          data: [28.5, 30.2, 32.1, 32.5],
          borderColor: '#10b981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Profit Margin Trend'
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 50,
            ticks: {
              callback: function(value) {
                return value + '%';
              }
            }
          }
        }
      }
    });
  }

  initCategoryMarginChart() {
    const ctx = document.getElementById('category-margin-chart').getContext('2d');

    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Appetizers', 'Main Courses', 'Desserts', 'Beverages'],
        datasets: [{
          label: 'Average Margin %',
          data: [45.2, 28.7, 52.1, 78.3],
          backgroundColor: [
            '#3b82f6',
            '#10b981',
            '#f59e0b',
            '#ef4444'
          ]
        }]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Margin by Category'
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: function(value) {
                return value + '%';
              }
            }
          }
        }
      }
    });
  }
}

// Initialize profit margin management
document.addEventListener('DOMContentLoaded', () => {
  new ProfitMarginManager();
});
```

## 📊 **Success Metrics**

### **1. Financial Metrics**
- Average profit margin improvement
- Number of items above target margin
- Total profit increase
- Cost reduction achievements

### **2. Operational Metrics**
- Time saved in cost calculations
- Accuracy of cost tracking
- Menu optimization decisions made
- Price adjustment frequency

### **3. User Adoption**
- Percentage of items with cost data
- Daily active users of profit tools
- Report generation frequency
- Feature utilization rates

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Cost Tracking (Weeks 1-3)**
- Database schema implementation
- Basic cost recording interface
- Profit margin calculations
- Simple reporting dashboard

### **Phase 2: Advanced Features (Weeks 4-6)**
- Recipe-based costing
- Ingredient cost management
- Target margin setting
- Automated alerts

### **Phase 3: Analytics & Reporting (Weeks 7-8)**
- Comprehensive reporting suite
- Visual analytics dashboard
- Trend analysis
- Export capabilities

### **Phase 4: Optimization Tools (Weeks 9-10)**
- Price optimization suggestions
- Menu engineering matrix
- Competitive analysis
- AI-powered recommendations

## 🎯 **Acceptance Criteria**

### **Must Have**
- ✅ Record production costs per menu item
- ✅ Calculate profit margins automatically
- ✅ Visual profit margin reports
- ✅ Cost breakdown by component
- ✅ Target margin setting and tracking
- ✅ Historical cost and margin tracking

### **Should Have**
- ✅ Recipe-based cost calculation
- ✅ Ingredient cost database
- ✅ Margin trend analysis
- ✅ Category-level profitability
- ✅ Automated margin alerts

### **Could Have**
- ✅ AI-powered pricing suggestions
- ✅ Competitive pricing analysis
- ✅ Advanced menu engineering
- ✅ Supplier price integration

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

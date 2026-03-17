# Menu Item Profit Margin Tracking Feature Request

## 📋 Feature Overview

**Feature Name**: Menu Item Profit Margin Tracking and Reporting  
**Priority**: High  
**Category**: Financial Management & Analytics  
**Estimated Effort**: Large (8-10 weeks)  
**Target Release**: Q2 2026  
**Status**: Requirements Finalized - Ready for Implementation

## 🎯 User Story

**As a** restaurant manager  
**I want to** track the cost of production and profit margin for each menu item  
**So that** I can make data-driven pricing decisions and optimize menu profitability

## ✅ Requirements Clarifications (Finalized)

### **Scope Decisions**
- **MVP Approach**: Manual cost entry per menuitem (Option A) - Simple fields for ingredient, labor, overhead costs
- **Target Users**: Both staff/admin interface AND customer-facing integration (smartmenu optimization)
- **Data Entry Methods**: Manual entry, bulk CSV import, AI estimation during OCR import, and future supplier integration
- **Ingredient Database**: Hybrid model - shared ingredient database with restaurant-specific overrides (supports chains)
- **Recipe Costing**: Track ingredient quantities only (no waste factors in Phase 1)
- **Cost Override**: Allow manual override of auto-calculated recipe costs
- **Margin Targets**: Three-level inheritance (Restaurant → Category → Item)
- **Alerts**: Visual indicators only (no email/push notifications in Phase 1)
- **Smartmenu Integration**: Semi-automatic ordering suggestions initially, with option to enable fully automatic in future
- **Customer Visibility**: None - purely internal data for staff
- **Reporting**: Full suite (list view, dashboard, charts) from Phase 1
- **Historical Tracking**: Version all cost changes from day 1
- **Order Analytics Integration**- **Order Analytics Integration**- **Order Analytics Integration**- **Order Analytics Integration**- re high-margin
- **Size Mappings**: Yes - different costs/margins for different sizes
- **Data Model**: Normalized (separate tables for flexibility)
- **Ingredient Model**: Extend existing `Ingredient` model with new fields
- **Supplier Integration**: Nice-to-have future enhancement (design schema to accommodate)

## 📖 Detailed Requirements

### **Phase 1: Core Cost Tracking (Weeks 1-3)**

#### **1.1 Manual Cost Entry**
- [ ] Add cost fields to menuitem management interface
- [ ] Four cost components: ingredient_cost, labor_cost, packaging_cost, overhead_cost
- [ ] Real-time profit margin calculation display
- [ ] Visual margin status indicators (above target / below target / critical)
- [ ] Save cost history with versioning (track changes over time)
- [ ] Notes field for cost entry context

#### **1.2 Extend Ingredient Model**
- [ ] Add `restaurant_id` (nullable for shared ingredients)
- [ ] Add `parent_ingredient_id` (for restaurant-specific overrides of shared ingredients)
- [ ] Add `unit_of_measure` (kg, liters, pieces, etc.)
- [ ] Add `current_cost_per_unit` (decimal)
- [ ] Add `supplier_id` (nullable, for future integration)
- [ ] Add `category` (produce, meat, dairy, etc.)
- [ ] Add `is_shared` boolean flag
- [ ] Keep existing `archived` field

#### **1.3 Basic Reporting**
- [ ] Simple list view: item name, cost, price, margin $, margin %
- [ ] Filter by category, margin status, date range
- [ ] Sort by margin %, profit $, item name
- [ ] Export to CSV
- [ ] Visual margin status badges

#### **1.4 AI Cost Estimation During OCR Import**
- [ ] Integrate with existing OCR menu import flow
- [ ] Use GPT to estimate ingredient costs based on menu item description
- [ ] Suggest labor/overh- [ ] Suggest labor/overh- [ ] Suggest labor/overh- [ ] Suggest ni- [ ] Suggest labor/overh- [ ] Sugge")
- [- [- [- [- [- [- [- [- [- [- [- [-  before finalizing
- [ ] Learn from manual corrections to improve future estimates

### **Phase 2: Recipe-Based Costing & Advanced Features (Weeks 4-6)**

#### **2.1 Recipe Ingredients**
- [ ] Create `menuitem_ingredient_quantities` table (extends existing `menuitem_ingredient_mappings`)
- [ ] Add quantity and unit fields to ingredient mappings
- [ ] Auto-calculate ingredient cost from (quantity × ingredient.current_cost_per_unit)
- [ ] Display recipe cost breakdown in UI
- [ ] Allow manual override of calculated costs
- [ ] Track which cost source is active (manual vs. recipe-calculated)

#### **2.2 Ingredient Cost Management**
- [ ] Ingredient library interface (restaurant-scoped and shared)
- [ ] Bulk import ingredients from CSV
- [ ] Update ingredient costs (creates - [ ] Update ingredient costs (creates - [ ] Update ingredient costs (ems use each ingredient
- [ ] Recalculate affected menuitem costs when ingredient costs change

#### **2.3 Profit Margin Targets**
- [ ] Set restaurant-level default target margin %
- [ ] Set category-level target margins (inherits from restaurant)
- [ ] Set item-level target margins (inherits from category)
- [ ] Set minimum acceptable margin thresholds
- [ ] Effective date ranges for seasonal targets
- [ ] Visual indicators when items fall below targets

### **Phase 3: Analytics & Reporting Dashboard (Weeks 7-8)**

#### **3.1 Profit Margin Dashboard**
- [ ] Summary cards: Average Margin %, Total Profit $, Items Above Target %
- [ ] Trend comparison (vs. previous period)
- [ ] Margin trend chart (line graph over time)
- [ ] Category margin breakdown (bar chart)
- [ ] Top 10 most profitable items
- [ ] Bottom 10 underperforming items
- [ ] Filter by date range, category, menu

#### **3.2 Order Analytics Integration**
- [ ] Track actual profit per order (sum of item margins × quantities)
- [ ] Daily/weekly/monthly profit reports
- [ ] Profit by time of day, day of week
- [ ] Profit by server/staff member
- [ ] Customer lifetime profit value

#### **3.3 Inventory Integration**
- [ ] Flag high-margin items with low inventory
- [ ] Alert when profitable items are out of stock
- [ ] Suggest reordering based on profitability + demand
- [ ] Track inventory turnover vs. profitability

#### **3.4 Size Mapping Integration**
- [ ] Different costs for different sizes (e.g., glass vs. bottle wine)
- [ ] Calculate margin for each size variant
- [ ] Display size-specific - [ ] Display size-specific - [ ] Display size-specific - [ ] Display hase 4- [ ] Display size-specific - [ ] Di(Weeks 9-- [ ] Display size-specific - [ ] Display ring**- [ ] Display size-specific - [ ] Display data
- [ ] Generate suggested menu sequence optimizations
- [ ] Show before/after preview
- [ ] Staff approves/rejects suggestions
- [ ] Track optimization impa- [ ] Track optimization impa- [ ] Track optimization impa- [ts

#### **4.2 Fully Automatic Mode (Optional Enable)**
- [ ] Restaurant setting to enable auto-optimization
- [ ] Configurable ru- [ ] Configurable ru- [ ] Configumarg- [ ] Configurable ru- [ ] Configon't move items more than X positions)
- [ ] Automatic reordering based on real-time data
- [ ] Override controls for special items (signature dishes)

#### *#### *#### *#### *#### *#### *#### *#### *### optimization suggestions based on margin targets
- [ ] Menu engineering matrix (Stars, Plowhorses, Puzzles, Dogs)
- [ ] Identify underpriced high-demand items
- [ ] Suggest bundling opportunities
- [ ] Seasonal pricing recommendations
- [ ] Competitive pricing intelligence (future: marketplace data)

## 🔧 Technical Specifications

### **Database Schema Updates**

```sql
-- Extend existing ingredie-- Extend existing ingredie-- Extend existing irestau-- Extend existing ingredie--par-- Extend existing ingredie-- Extend e un-- Extend existing ingredie-- Extend existing ingredie-- Extend existing irestau-- Extend eupplier_id BIGINT,
  ADD COLUMN category VARCHAR(100),
  ADD COLUMN is_shared BOOLEAN DEFAULT false,
  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F DD I  ADD F  ADD F  ADD F  ADD F  ADD F  ADD F  ADD FEX idx_category (category),
  ADD INDEX idx_is_shared (is_shared);

-- New: Menu item costs (versioned history)
CREATE TABLE menuitem_costs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  menuitem_id BIGINT NOT NULL,
  ingredient_cost DECIMAL(10,4) DEFAULT 0,
  labor_cost DECIMAL(10,4) DEFAULT 0,
  packaging_cost DECIMAL(10,4) DEFAULT 0,
  overhead_cost DECIMAL(10,4) DEFAULT 0,
  total_cost DECIMAL(10,4) GENERATED ALWA  total_cost DECIMAL(10,4) GE labo  total_cost DECIMAL(10,4) GENhead_cost
  ) STORED,
  cost_source VARCHAR(50) DEFAULT 'manual', -- 'manual', 'recipe_calculated', 'ai_estimated'
  is_active BOOLEAN DEFAULT true,
  effective_date DATE NOT NULL,
  notes TEXT,
  created_by_user_id BIGINT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  FOREIGN KEY (menuitem_id) REFERENCES menuitems(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_menuitem_active (menuitem_id, is_active),
  INDEX idx_effective_date (effective_date)
);

-- New: Recipe ingredient quantities (extends existing mappings)
CREATE TABLE menuitemCREATE TABLE menuitemCREATE TABLE menuiIMARYCREATE TABLE menuitemCREATE teCREATE TABLE menuitemCREATE TABLE menuBICREATE TABLE menuitemCREATE TIMAL(10,4) NOT NULL,
  unit VARCHAR(50) NOT NULL,
  cost_per_unit DECIMAL(10,4),
  total_cost DECIMAL(10,4) GENERATED ALWAYS AS (quantity * cost_per_unit) STORED,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  FOREIGN KEY (menuitem_id) REFERENCES menuitems(id) ON DELET  FOREIGN KEY (menuitem_id) REFERENCES menuitems(id) ON DELET  FOREIGN KEY (menuitem_id) REnuitem_ingredient (menuitem_id, ingredient_id),
  INDEX idx_menuitem_id (menuitem_id),
  INDEX idx_ingredient_id (ingredient_id)
);

-- New: Profit margin targets (three-level inheritance)
CREATE TABLE profit_margin_targets (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  restaurant_id BIGINT,
  menusection_id BIGINT,
  menuitem_id BIGINT,
  target_margin_percentage DECIMAL(5,2) NOT NULL,
  minimum_margin_percentage DECIMAL(5,2),
  effective_from DATE NOT NULL,
  effective_to DATE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
  FOREIGN KEY (menusection_id) REFERENCES menusections(id) ON D  FOREIGN KEY (menusectionEY (m  FOREIGN KEY (menusection_id) REFERENCES menusections(id) ON D  FOREIGN KEY (med   FOREIGN KEY (menusection_id) nu  FOREIGN KEY (menusection_id) INDEX idx_menuitem_id (menuitem_id),
  INDEX idx_effective_dates (effective_from, effective_to),
  CHECK (
    (restaurant_id IS NOT NULL AND menusection_id IS NULL AND menuitem_id IS NULL) OR
    (restaurant_id IS NULL AND menusection_id IS NOT NULL AND menuitem_id IS NULL) OR
    (restau    (restau    (restau    (restau    (restau    (ruitem_    (restau    (restau    (restau  redient cost history
CREATE TABLE ingredieCREATE TABLE ingredieC BIGINT PRIMARY KEY AUTO_INCREMENT,
  ingredient_id BIGINT NOT NULL,
  cost_per_unit DECIMAL(10,4) NOT NULL,
  effective_date DATE NOT NULL,
  source VARCHAR(50), -- 'manual', 'supplier_api', 'ai_estimated'
  notes TEXT,
  created_by_user_id BIGINT,
  created_at   created_at   created_at   created_at   created_at   created_at   creaents(  created_at   created_at   created_at   created_at   created_at   created_at   creaents(  created_at   created_at   created_at   created_at   created_at   created_at   creaents(  created_at   created_at   created_at   created_at   created_at   created_at   creaents(  createra  created_at   created_at   created_at   created_at   creation_type VA  created_at   created_at   created_at   created_at   created_at   created_at   creNB,
  suggested_state JSONB,
  expected_impact JSONB, -- profit increase, margin improvem  expected_impact JSONB, -- profit increase, margin improvem  expected_impact JSONB, -- profit increase, margin improvem 
                                                                          ES restaurants(id) ON DELETE CASCADE,
                                ES menus(                      
  INDEX idx_restaurant_status (restaurant_id, status),
  INDEX idx_created_at (created_at)
);
```

### **Model Extensions**

```ruby
# app/models/menuitem.rb
class Menuitem < ApplicationRecord
  has_many :menuitem_costs, dependent: :destroy
  has_many :menuitem_ingredient_quantities, dependent: :destroy
  has_many :ingredients, through: :menuitem_ingredient_quantities
  has_one :profit_margin_target, dependent: :destroy
  
  # Get current active cost
  def current_cost
    menuitem_costs.where(is_active: true).order(effective_date: :desc).first
  end
  
  # Calculate profit margin
  def profit_margin
    return 0 unless price && current_cost
    price - current_cost.total_cost
  end
  
  def profit_margin_percentage
    return 0 unless price && price > 0 && current_cost
    ((profit_margin / price) * 100).round(2)
  end
  
  # Get effective margin target (with inheritance)
  def effective_margin_target
    # Item-level target takes precedence
    return profit_margin_target if profit_margin_target
    
    # Then category/section-level
    section_target = menusection&.profit_margin_target
    return section_target if section_target
    
    # Finally restaurant-level
    menusection&.menu&.restaurant&.profit_margin_target
  end
  
  def margin_status
    target = effective_margin_target&.target_margin_percentage
    return 'no_target' unless target
    
    current = profit_margin_percentage
    minimum = effective_margin_target&.minimum_margin_percentage || 0
    
    if     if     if     if     if     if     if     if     if     if     if     'below_target'
    else
      'critical'
    end
  end
  
  # Calculate cost from recipe
  def calculate_recipe_cost
    menuitem_ingredient_quantities.sum(&:total_cost)
  end
end

# app/models/ingredient.rb
class Ingredient < ApplicationRecord
  belongs_to :restaurant, optional: true
  belongs_to :parent_ingredient, class_name: 'Ingredient', optional: true
  has_many :child_ingredients, class_name: 'Ingredient', foreign_key: 'parent_ingredient_id'
  has_many :menuitem_ingredient_quantities, dependent: :destroy
  has_many :menuitems, through: :menuitem_ingredient_quantities
  has_many :ingredient_cost_histories, dependent: :destroy
  
  scope :shared, -> { where(is_shared: true, restaurant_id: n  scope :shared, -_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_  scope :shared, -> { where(is_shaest  san  scope :shared, -> { where(is_shtive_c  scope :shared, -> { where(is_shared: true, restaurant_id: n  scope_unit |  scope :shared, -> { where(is_shared: true, restaurant_id: n  scope :shared, -_restaurant, -imp  scopet   scope :shared 6  scohs)  scumber of items above target margin (target: 80%)
- Total profit increase (target: +10% in 6 months)
- Cost reduction through optimization (target: -5%)

### **Operational Efficiency**
- Time saved in cost calculations (target: 80% reduction)
- Accuracy of cost tracking (target: 95%+ accuracy)
- Menu optimization decisions made per month (target: 2-4)
- Price adjustments based on margin data (target: 10+ per month)

### **User Adoption**
- Percentage of menuitems with cost data (target: 90% within 3 months)
- Daily active users of profit tools (target: 50% of restaurant managers)
- Report generation frequency (target: 3+ per week per restaurant)
- Feature utilization rate (target: 70% of restaurants using within 6 months)

## 🚀 Implementation Roadmap

### **Phase 1: Core Cost Tracking (Weeks 1-3)**
- Week 1: Database migrations, extend Ingredient model
- Week 2: Manual cost entry UI, profit calculations
- Week 3: Basic reporting, AI cost estimation in OCR flow

### **Phase 2: Recipe-Based Costing (Weeks 4-6)**
- Week 4: Recipe ingredient quantities, auto-- Week 4: Recipe ingredient quantities, auto-- Wein- Week 4: Recipe ingredient quantities, auto-- Wee visual indicators

### **Phase 3:### **Phase 3:### **Phase 3:### **Phase 3:### **Phase 3:rd### **Phase 3:### **Phase 3:### **Phase 3:### ** 8: Inventory integration, size mapping support, exports

### **Phase 4: Optimization Tools (Weeks 9-10)**
- Week 9: Semi-automatic menu ordering suggestions
- Week 10: AI recommendations, fully automatic mode (optional)

---

**Created**: October 11, 2025  
**Updated**: March 16, 2026  
**Status**: Requirements Finalized - Ready for Implementation  
**Priority**: High  
**Approved By**: User (Q&A Session Complete)

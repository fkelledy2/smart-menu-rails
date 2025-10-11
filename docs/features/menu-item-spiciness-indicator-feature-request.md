# Menu Item Spiciness Indicator Feature Request

## 📋 **Feature Overview**

**Feature Name**: Menu Item Spiciness Persistence and Visualization with OCR Auto-Detection
**Priority**: Medium
**Category**: Menu Management & User Experience
**Estimated Effort**: Medium (5-7 weeks)
**Target Release**: Q2 2026

## 🎯 **User Story**

**As a** restaurant owner
**I want to** add spiciness indicators (chili peppers) to my menu items and have them automatically detected during OCR import
**So that** customers can easily identify the heat level of dishes and make informed ordering decisions

**As a** customer
**I want to** see clear spiciness indicators on menu items
**So that** I can choose dishes that match my spice tolerance and dietary preferences

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Spiciness Data Model**
- **Spiciness Scale**: 5-level scale (0-4 chilies) for heat indication
- **Database Persistence**: Store spiciness level for each menu item
- **Flexible System**: Support for custom spiciness descriptions
- **Historical Tracking**: Track spiciness changes over time
- **Category Support**: Different scales for different cuisine types

#### **2. Visual Spiciness Indicators**
- **Chili Pepper Icons**: Attractive, scalable chili pepper graphics
- **Responsive Display**: Consistent appearance across all devices
- **Color Coding**: Progressive color intensity (green to red)
- **Accessibility**: Screen reader support and high contrast options
- **Customization**: Restaurant-specific styling options

#### **3. Menu Management Interface**
- **Easy Assignment**: Simple interface for setting spiciness levels
- **Bulk Operations**: Update multiple items simultaneously
- **Visual Preview**: Real-time preview of how indicators will appear
- **Import/Export**: CSV support for bulk spiciness data management
- **Validation**: Ensure spiciness levels are within valid range

#### **4. OCR Auto-Detection (Nice to Have)**
- **Text Analysis**: Scan menu descriptions for spice-related keywords
- **Machine Learning**: Train model to recognize spiciness indicators
- **Confidence Scoring**: Provide confidence levels for auto-detected spiciness
- **Manual Override**: Allow manual correction of auto-detected values
- **Learning System**: Improve accuracy based on manual corrections

### **Secondary Requirements**

#### **5. Customer-Facing Features**
- **Menu Display**: Show spiciness indicators on all customer-facing menus
- **Filtering**: Allow customers to filter menu by spiciness level
- **Search Integration**: Include spiciness in menu search functionality
- **Mobile Optimization**: Touch-friendly spiciness selection
- **Tooltip Information**: Detailed spiciness descriptions on hover/tap

#### **6. Analytics and Reporting**
- **Spiciness Analytics**: Track customer preferences and ordering patterns
- **Heat Map Reports**: Visual representation of menu spiciness distribution
- **Customer Insights**: Analyze spiciness preferences by demographics
- **Menu Optimization**: Recommendations for spiciness level adjustments
- **A/B Testing**: Test different spiciness visualization approaches

## 🔧 **Technical Specifications**

### **Database Schema**

#### **1. Menu Item Spiciness Extension**
```sql
-- Add spiciness columns to menu_items table
ALTER TABLE menu_items ADD COLUMN spiciness_level INTEGER DEFAULT 0;
ALTER TABLE menu_items ADD COLUMN spiciness_description VARCHAR(100);
ALTER TABLE menu_items ADD COLUMN spiciness_auto_detected BOOLEAN DEFAULT false;
ALTER TABLE menu_items ADD COLUMN spiciness_confidence_score DECIMAL(3,2);
ALTER TABLE menu_items ADD COLUMN spiciness_updated_at TIMESTAMP;

-- Add constraints
ALTER TABLE menu_items ADD CONSTRAINT chk_spiciness_level
  CHECK (spiciness_level >= 0 AND spiciness_level <= 4);

-- Add indexes
CREATE INDEX idx_menu_items_spiciness_level ON menu_items(spiciness_level);
CREATE INDEX idx_menu_items_spiciness_updated_at ON menu_items(spiciness_updated_at);

-- Spiciness history tracking
CREATE TABLE menu_item_spiciness_history (
  id BIGINT PRIMARY KEY,
  menu_item_id BIGINT NOT NULL,
  old_spiciness_level INTEGER,
  new_spiciness_level INTEGER,
  changed_by_user_id BIGINT,
  change_reason VARCHAR(255),
  auto_detected BOOLEAN DEFAULT false,
  confidence_score DECIMAL(3,2),
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
  FOREIGN KEY (changed_by_user_id) REFERENCES users(id),
  INDEX idx_menu_item_id (menu_item_id),
  INDEX idx_created_at (created_at)
);

-- Spiciness keywords for OCR detection
CREATE TABLE spiciness_keywords (
  id BIGINT PRIMARY KEY,
  keyword VARCHAR(100) NOT NULL,
  spiciness_level INTEGER NOT NULL,
  language VARCHAR(10) DEFAULT 'en',
  confidence_weight DECIMAL(3,2) DEFAULT 1.0,
  cuisine_type VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  UNIQUE KEY unique_keyword_language (keyword, language),
  INDEX idx_spiciness_level (spiciness_level),
  INDEX idx_language (language),
  INDEX idx_cuisine_type (cuisine_type)
);
```

### **Backend Implementation**

#### **1. Spiciness Model and Service**
```ruby
class MenuItem < ApplicationRecord
  SPICINESS_LEVELS = {
    0 => { name: 'No Heat', description: 'Mild, no spice', icon: '' },
    1 => { name: 'Mild', description: 'Gentle warmth', icon: '🌶️' },
    2 => { name: 'Medium', description: 'Noticeable heat', icon: '🌶️🌶️' },
    3 => { name: 'Hot', description: 'Significant spice', icon: '🌶️🌶️🌶️' },
    4 => { name: 'Very Hot', description: 'Intense heat', icon: '🌶️🌶️🌶️🌶️' }
  }.freeze

  validates :spiciness_level, inclusion: { in: 0..4 }

  has_many :spiciness_history_entries,
           class_name: 'MenuItemSpicinessHistory',
           dependent: :destroy

  before_update :track_spiciness_changes

  def spiciness_info
    SPICINESS_LEVELS[spiciness_level || 0]
  end

  def spiciness_display
    return '' if spiciness_level.nil? || spiciness_level.zero?

    {
      level: spiciness_level,
      name: spiciness_info[:name],
      description: spiciness_description || spiciness_info[:description],
      icon: spiciness_info[:icon],
      auto_detected: spiciness_auto_detected,
      confidence: spiciness_confidence_score
    }
  end

  private

  def track_spiciness_changes
    if spiciness_level_changed?
      MenuItemSpicinessHistory.create!(
        menu_item: self,
        old_spiciness_level: spiciness_level_was,
        new_spiciness_level: spiciness_level,
        changed_by_user_id: Current.user&.id,
        change_reason: 'Manual update',
        auto_detected: false
      )
    end
  end
end

class SpicinessDetectionService
  def initialize
    @keywords = SpicinessKeyword.active.includes(:spiciness_level)
  end

  def analyze_text(text, cuisine_type = nil)
    return { level: 0, confidence: 0.0, keywords: [] } if text.blank?

    detected_keywords = find_spiciness_keywords(text, cuisine_type)
    return { level: 0, confidence: 0.0, keywords: [] } if detected_keywords.empty?

    calculate_spiciness_level(detected_keywords)
  end

  private

  def find_spiciness_keywords(text, cuisine_type)
    keywords = @keywords
    keywords = keywords.where(cuisine_type: [cuisine_type, nil]) if cuisine_type

    found_keywords = []
    text_lower = text.downcase

    keywords.each do |keyword|
      if text_lower.include?(keyword.keyword.downcase)
        found_keywords << {
          keyword: keyword.keyword,
          level: keyword.spiciness_level,
          weight: keyword.confidence_weight
        }
      end
    end

    found_keywords
  end

  def calculate_spiciness_level(keywords)
    return { level: 0, confidence: 0.0, keywords: [] } if keywords.empty?

    # Weighted average calculation
    total_weight = keywords.sum { |k| k[:weight] }
    weighted_sum = keywords.sum { |k| k[:level] * k[:weight] }

    level = (weighted_sum / total_weight).round
    confidence = [total_weight / keywords.length, 1.0].min

    {
      level: [level, 4].min,
      confidence: confidence,
      keywords: keywords.map { |k| k[:keyword] }
    }
  end
end
```

#### **2. OCR Integration Enhancement**
```ruby
class OcrMenuImportService
  def process_menu_item(item_data)
    # Existing OCR processing...

    # Add spiciness detection
    spiciness_result = detect_spiciness(item_data)

    menu_item = create_menu_item(item_data)

    if spiciness_result[:level] > 0 && spiciness_result[:confidence] > 0.6
      menu_item.update!(
        spiciness_level: spiciness_result[:level],
        spiciness_auto_detected: true,
        spiciness_confidence_score: spiciness_result[:confidence],
        spiciness_description: generate_spiciness_description(spiciness_result)
      )

      track_auto_detection(menu_item, spiciness_result)
    end

    menu_item
  end

  private

  def detect_spiciness(item_data)
    text_to_analyze = [
      item_data[:name],
      item_data[:description],
      item_data[:ingredients]
    ].compact.join(' ')

    SpicinessDetectionService.new.analyze_text(
      text_to_analyze,
      item_data[:cuisine_type]
    )
  end

  def generate_spiciness_description(result)
    base_description = MenuItem::SPICINESS_LEVELS[result[:level]][:description]
    keywords = result[:keywords].join(', ')

    "#{base_description} (detected from: #{keywords})"
  end

  def track_auto_detection(menu_item, result)
    MenuItemSpicinessHistory.create!(
      menu_item: menu_item,
      old_spiciness_level: 0,
      new_spiciness_level: result[:level],
      change_reason: "OCR auto-detection (confidence: #{result[:confidence]})",
      auto_detected: true,
      confidence_score: result[:confidence]
    )
  end
end
```

### **Frontend Implementation**

#### **1. Spiciness Management Interface**
```html
<!-- Menu Item Form Enhancement -->
<div class="spiciness-section">
  <label class="form-label">Spiciness Level</label>

  <div class="spiciness-selector">
    <div class="spiciness-options">
      <% MenuItem::SPICINESS_LEVELS.each do |level, info| %>
        <div class="spiciness-option" data-level="<%= level %>">
          <input type="radio"
                 name="menu_item[spiciness_level]"
                 value="<%= level %>"
                 id="spiciness_<%= level %>"
                 <%= 'checked' if @menu_item.spiciness_level == level %>>
          <label for="spiciness_<%= level %>" class="spiciness-label">
            <div class="spiciness-visual">
              <%= info[:icon] %>
            </div>
            <div class="spiciness-text">
              <strong><%= info[:name] %></strong>
              <small><%= info[:description] %></small>
            </div>
          </label>
        </div>
      <% end %>
    </div>
  </div>

  <div class="spiciness-custom-description">
    <label for="spiciness_description">Custom Description (optional)</label>
    <input type="text"
           name="menu_item[spiciness_description]"
           id="spiciness_description"
           value="<%= @menu_item.spiciness_description %>"
           placeholder="e.g., 'Made with ghost peppers'">
  </div>

  <% if @menu_item.spiciness_auto_detected? %>
    <div class="auto-detection-info">
      <i class="icon-robot"></i>
      <span>Auto-detected with <%= (@menu_item.spiciness_confidence_score * 100).to_i %>% confidence</span>
      <button type="button" class="btn-link" onclick="showDetectionDetails()">
        View Details
      </button>
    </div>
  <% end %>
</div>
```

#### **2. Customer-Facing Spiciness Display**
```html
<!-- Menu Item Card Enhancement -->
<div class="menu-item-card">
  <div class="menu-item-header">
    <h3 class="menu-item-name"><%= menu_item.name %></h3>
    <% if menu_item.spiciness_level > 0 %>
      <div class="spiciness-indicator"
           data-level="<%= menu_item.spiciness_level %>"
           title="<%= menu_item.spiciness_display[:description] %>">
        <span class="spiciness-icon">
          <%= menu_item.spiciness_display[:icon] %>
        </span>
        <span class="spiciness-text">
          <%= menu_item.spiciness_display[:name] %>
        </span>
      </div>
    <% end %>
  </div>

  <div class="menu-item-description">
    <%= menu_item.description %>
  </div>

  <div class="menu-item-footer">
    <span class="price"><%= menu_item.formatted_price %></span>
    <button class="add-to-cart-btn">Add to Cart</button>
  </div>
</div>
```

#### **3. Spiciness Filter Interface**
```html
<!-- Menu Filter Enhancement -->
<div class="menu-filters">
  <div class="filter-group">
    <label class="filter-label">Spice Level</label>
    <div class="spiciness-filter">
      <div class="spiciness-range-slider">
        <input type="range"
               id="spiciness-filter"
               min="0"
               max="4"
               value="4"
               class="spiciness-slider">
        <div class="spiciness-labels">
          <span data-level="0">No Heat</span>
          <span data-level="1">🌶️</span>
          <span data-level="2">🌶️🌶️</span>
          <span data-level="3">🌶️🌶️🌶️</span>
          <span data-level="4">🌶️🌶️🌶️🌶️</span>
        </div>
      </div>
      <div class="filter-description">
        <span id="spiciness-filter-text">Show all spice levels</span>
      </div>
    </div>
  </div>
</div>
```

### **CSS Styling**

#### **1. Spiciness Visual Design**
```css
.spiciness-indicator {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 6px;
  border-radius: 12px;
  font-size: 0.875rem;
  font-weight: 500;
}

.spiciness-indicator[data-level="0"] {
  background: #f3f4f6;
  color: #6b7280;
}

.spiciness-indicator[data-level="1"] {
  background: #fef3c7;
  color: #d97706;
}

.spiciness-indicator[data-level="2"] {
  background: #fed7aa;
  color: #ea580c;
}

.spiciness-indicator[data-level="3"] {
  background: #fecaca;
  color: #dc2626;
}

.spiciness-indicator[data-level="4"] {
  background: #fca5a5;
  color: #b91c1c;
}

.spiciness-icon {
  font-size: 1rem;
  line-height: 1;
}

.spiciness-selector {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 12px;
  margin: 12px 0;
}

.spiciness-option input[type="radio"] {
  display: none;
}

.spiciness-label {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 12px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.spiciness-option input[type="radio"]:checked + .spiciness-label {
  border-color: #f59e0b;
  background-color: #fffbeb;
}

.spiciness-visual {
  font-size: 1.5rem;
  margin-bottom: 4px;
}

.spiciness-text {
  text-align: center;
}

.spiciness-text strong {
  display: block;
  font-size: 0.875rem;
  color: #374151;
}

.spiciness-text small {
  font-size: 0.75rem;
  color: #6b7280;
}

.auto-detection-info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 6px;
  font-size: 0.875rem;
  color: #0369a1;
  margin-top: 8px;
}

.spiciness-filter {
  width: 100%;
  max-width: 300px;
}

.spiciness-range-slider {
  position: relative;
  margin-bottom: 8px;
}

.spiciness-slider {
  width: 100%;
  height: 6px;
  border-radius: 3px;
  background: linear-gradient(to right, #10b981, #f59e0b, #ef4444);
  outline: none;
  -webkit-appearance: none;
}

.spiciness-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #ffffff;
  border: 2px solid #f59e0b;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.spiciness-labels {
  display: flex;
  justify-content: space-between;
  margin-top: 4px;
  font-size: 0.75rem;
}

@media (max-width: 768px) {
  .spiciness-selector {
    grid-template-columns: repeat(2, 1fr);
  }

  .spiciness-indicator {
    font-size: 0.75rem;
  }

  .spiciness-icon {
    font-size: 0.875rem;
  }
}
```

### **JavaScript Implementation**

#### **1. Spiciness Management**
```javascript
class SpicinessManager {
  constructor() {
    this.initEventListeners();
    this.initFilter();
  }

  initEventListeners() {
    // Spiciness selector
    document.querySelectorAll('.spiciness-option input').forEach(input => {
      input.addEventListener('change', this.handleSpicinessChange.bind(this));
    });

    // Filter slider
    const slider = document.getElementById('spiciness-filter');
    if (slider) {
      slider.addEventListener('input', this.handleFilterChange.bind(this));
    }
  }

  handleSpicinessChange(event) {
    const level = parseInt(event.target.value);
    const preview = document.getElementById('spiciness-preview');

    if (preview) {
      this.updatePreview(preview, level);
    }

    // Track analytics
    this.trackSpicinessSelection(level);
  }

  updatePreview(preview, level) {
    const levelInfo = this.getSpicinessInfo(level);

    preview.innerHTML = `
      <div class="spiciness-indicator" data-level="${level}">
        <span class="spiciness-icon">${levelInfo.icon}</span>
        <span class="spiciness-text">${levelInfo.name}</span>
      </div>
    `;
  }

  handleFilterChange(event) {
    const maxLevel = parseInt(event.target.value);
    const filterText = document.getElementById('spiciness-filter-text');

    // Update filter description
    if (maxLevel === 4) {
      filterText.textContent = 'Show all spice levels';
    } else {
      const levelInfo = this.getSpicinessInfo(maxLevel);
      filterText.textContent = `Show up to ${levelInfo.name}`;
    }

    // Filter menu items
    this.filterMenuItems(maxLevel);
  }

  filterMenuItems(maxLevel) {
    const menuItems = document.querySelectorAll('.menu-item-card');

    menuItems.forEach(item => {
      const indicator = item.querySelector('.spiciness-indicator');
      const itemLevel = indicator ?
        parseInt(indicator.getAttribute('data-level')) : 0;

      if (itemLevel <= maxLevel) {
        item.style.display = 'block';
      } else {
        item.style.display = 'none';
      }
    });

    // Update results count
    this.updateResultsCount();
  }

  getSpicinessInfo(level) {
    const levels = {
      0: { name: 'No Heat', icon: '' },
      1: { name: 'Mild', icon: '🌶️' },
      2: { name: 'Medium', icon: '🌶️🌶️' },
      3: { name: 'Hot', icon: '🌶️🌶️🌶️' },
      4: { name: 'Very Hot', icon: '🌶️🌶️🌶️🌶️' }
    };

    return levels[level] || levels[0];
  }

  trackSpicinessSelection(level) {
    // Google Analytics
    gtag('event', 'spiciness_selected', {
      'event_category': 'Menu Management',
      'event_label': `Level ${level}`,
      'value': level
    });
  }

  updateResultsCount() {
    const visibleItems = document.querySelectorAll('.menu-item-card[style*="block"], .menu-item-card:not([style*="none"])').length;
    const resultsCounter = document.getElementById('results-count');

    if (resultsCounter) {
      resultsCounter.textContent = `${visibleItems} items`;
    }
  }
}

// Initialize spiciness management
document.addEventListener('DOMContentLoaded', () => {
  new SpicinessManager();
});
```

## 📊 **Success Metrics**

### **1. Usage Metrics**
- Percentage of menu items with spiciness indicators
- Customer engagement with spiciness filters
- OCR auto-detection accuracy rate
- Manual override frequency

### **2. Business Metrics**
- Customer satisfaction with spice level accuracy
- Reduction in spice-related complaints
- Increase in menu item discovery
- Order completion rates for spicy items

### **3. Technical Metrics**
- OCR processing time impact
- Auto-detection confidence scores
- System performance with new features
- Mobile usability metrics

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Infrastructure (Weeks 1-2)**
- Database schema implementation
- Basic spiciness model and validations
- Admin interface for manual spiciness assignment
- Basic visual indicators

### **Phase 2: Customer Experience (Weeks 3-4)**
- Customer-facing spiciness display
- Menu filtering by spiciness level
- Mobile optimization
- Accessibility improvements

### **Phase 3: OCR Integration (Weeks 5-6)**
- Spiciness keyword database
- OCR auto-detection service
- Confidence scoring system
- Manual override interface

### **Phase 4: Enhancement & Analytics (Week 7)**
- Advanced analytics and reporting
- A/B testing framework
- Performance optimization
- Documentation and training

## 🎯 **Acceptance Criteria**

### **Must Have**
- ✅ 5-level spiciness scale (0-4 chilies)
- ✅ Visual chili pepper indicators
- ✅ Manual spiciness assignment interface
- ✅ Customer-facing spiciness display
- ✅ Menu filtering by spiciness level
- ✅ Mobile-responsive design

### **Should Have**
- ✅ OCR auto-detection of spiciness
- ✅ Confidence scoring for auto-detection
- ✅ Manual override capabilities
- ✅ Spiciness analytics and reporting
- ✅ Bulk spiciness management

### **Could Have**
- ✅ Custom spiciness descriptions
- ✅ Cuisine-specific spiciness scales
- ✅ Advanced ML-based detection
- ✅ Customer spice preference learning

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: Medium

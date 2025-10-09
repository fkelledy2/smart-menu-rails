# Smart Restaurant ID Detection System

## Overview

The Smart Restaurant ID Detection System provides intelligent, context-aware restaurant identification across the Smart Menu application. It uses multiple detection strategies with fallback mechanisms to ensure reliable restaurant context in all scenarios.

## Architecture

### Core Components

1. **RestaurantContext.js** - Main detection utility class
2. **ApplicationHelper** - Rails helper methods for context injection
3. **Module Integration** - Enhanced getRestaurantId() methods in all modules

### Detection Strategies (Priority Order)

#### 1. URL Path Analysis (Highest Priority)
- **Pattern**: `/restaurants/123`, `/restaurants/123/menus/456`
- **Reliability**: Highest - directly from URL structure
- **Use Case**: All restaurant-nested routes

```javascript
// Examples:
// /restaurants/123 → "123"
// /restaurants/123/menus/456 → "123"
// /restaurants/123/edit → "123"
```

#### 2. Context-Specific Data Attributes
- **Selectors**: `[data-restaurant-id]`, `[data-bs-restaurant]`, etc.
- **Reliability**: High - explicitly set in views
- **Use Case**: Table elements, form containers

```html
<!-- Examples: -->
<div data-restaurant-id="123">...</div>
<table data-bs-restaurant="123">...</table>
```

#### 3. Global DOM Elements
- **Selectors**: `#currentRestaurant`, `body[data-restaurant-id]`
- **Reliability**: Medium - application-wide context
- **Use Case**: Layout-level context

```html
<!-- Examples: -->
<div id="currentRestaurant">123</div>
<body data-restaurant-id="123">...</body>
```

#### 4. JavaScript Global Variables
- **Variables**: `window.currentRestaurant`, `window.restaurantContext`
- **Reliability**: Medium - programmatically set
- **Use Case**: Dynamic context setting

```javascript
// Examples:
window.currentRestaurant = { id: "123", name: "Restaurant Name" };
window.restaurantContext = "123";
```

#### 5. Meta Tags
- **Tags**: `<meta name="restaurant-id">`, `<meta property="restaurant:id">`
- **Reliability**: Medium - SEO and context metadata
- **Use Case**: Page-level context

```html
<!-- Examples: -->
<meta name="restaurant-id" content="123">
<meta property="restaurant:id" content="123">
```

#### 6. Local Storage (Lowest Priority)
- **Keys**: `currentRestaurantId`, `restaurant_id`
- **Reliability**: Low - persistence mechanism
- **Use Case**: Cross-session persistence

## Usage

### JavaScript Modules

```javascript
// In any module
class MyModule extends ComponentBase {
  getRestaurantId() {
    // Use enhanced detection system
    if (window.RestaurantContext) {
      return window.RestaurantContext.getRestaurantId(this.container);
    }
    
    // Fallback to basic detection
    return this.basicDetection();
  }
}
```

### Rails Views

#### 1. Add Restaurant Context Data Attributes

```erb
<!-- Table with restaurant context -->
<div class="table-container" <%= restaurant_context_data %>>
  <table id="menu-table" data-bs-menu="<%= @menu.id %>">
    <!-- Table content -->
  </table>
</div>
```

#### 2. Add Meta Tags for Context

```erb
<!-- In layout or view -->
<% restaurant_context_meta_tags %>
```

#### 3. Initialize JavaScript Context

```erb
<!-- In layout or view -->
<%= restaurant_context_script %>
```

#### 4. Enhanced Body Tag

```erb
<!-- In layout -->
<%= body_with_restaurant_context(class: "layout-body") do %>
  <!-- Body content -->
<% end %>
```

### Advanced Features

#### Caching System
- **Cache Duration**: 5 minutes
- **Cache Keys**: Context-specific (global, element-based)
- **Performance**: Reduces repeated DOM queries

#### Observer Pattern
```javascript
// Listen for restaurant context changes
window.RestaurantContext.addObserver((restaurantId) => {
  console.log('Restaurant changed to:', restaurantId);
  // Update UI, refresh data, etc.
});
```

#### URL Change Detection
- Automatically detects navigation changes
- Clears cache on route changes
- Works with both traditional and SPA navigation

#### Debug Information
```javascript
// Get debug info about detection
const debugInfo = window.RestaurantContext.getDebugInfo();
console.log('Restaurant Context Debug:', debugInfo);
```

## Implementation Examples

### 1. Menu Management Page

```erb
<!-- app/views/menus/edit.html.erb -->
<%= restaurant_context_meta_tags %>

<div class="menu-container" <%= restaurant_context_data(@menu.restaurant) %>>
  <div id="menu-menusection-table" 
       data-bs-menu="<%= @menu.id %>" 
       data-bs-restaurant="<%= @menu.restaurant.id %>">
  </div>
</div>

<%= restaurant_context_script(@menu.restaurant) %>
```

### 2. JavaScript Module

```javascript
// modules/menus/MenuModule.js
class MenuModule extends ComponentBase {
  init() {
    // Get restaurant ID using smart detection
    const restaurantId = this.getRestaurantId();
    
    if (restaurantId) {
      // Use nested routes
      this.ajaxURL = `/restaurants/${restaurantId}/menus.json`;
    } else {
      // Fallback to old routes
      this.ajaxURL = `/menus.json`;
    }
  }
  
  linkFormatter(cell) {
    const id = cell.getValue();
    const restaurantId = this.getRestaurantId();
    
    if (restaurantId) {
      return `<a href='/restaurants/${restaurantId}/menus/${id}/edit'>${name}</a>`;
    } else {
      return `<a href='/menus/${id}/edit'>${name}</a>`;
    }
  }
}
```

### 3. Table Configuration

```javascript
// config/tableConfigs.js
export const TableFormatters = {
  link: (cell) => {
    const restaurantId = window.RestaurantContext?.getRestaurantId();
    const menuId = cell.getTable().element.dataset.menu;
    
    if (restaurantId && menuId) {
      // Use nested routes
      return `<a href='/restaurants/${restaurantId}/menus/${menuId}/items/${id}/edit'>${name}</a>`;
    } else {
      // Fallback routes
      return `<a href='/items/${id}/edit'>${name}</a>`;
    }
  }
};
```

## Benefits

### 1. Reliability
- **Multiple fallback strategies** ensure restaurant context is always available
- **Graceful degradation** when context is missing
- **Error resilience** with comprehensive error handling

### 2. Performance
- **Intelligent caching** reduces DOM queries
- **Context-aware caching** optimizes for different scenarios
- **Lazy evaluation** only detects when needed

### 3. Maintainability
- **Centralized logic** in RestaurantContext utility
- **Consistent API** across all modules
- **Easy debugging** with comprehensive debug information

### 4. Flexibility
- **Multiple integration points** (URL, DOM, JavaScript, storage)
- **Observer pattern** for reactive updates
- **Configurable strategies** for different use cases

## Migration Guide

### From Basic Detection

```javascript
// OLD: Basic detection in each module
getRestaurantId() {
  const pathMatch = window.location.pathname.match(/\/restaurants\/(\d+)/);
  return pathMatch ? pathMatch[1] : null;
}

// NEW: Enhanced detection with fallbacks
getRestaurantId() {
  if (window.RestaurantContext) {
    return window.RestaurantContext.getRestaurantId(this.container);
  }
  // Keep old logic as fallback
  const pathMatch = window.location.pathname.match(/\/restaurants\/(\d+)/);
  return pathMatch ? pathMatch[1] : null;
}
```

### Adding Context to Views

```erb
<!-- OLD: Manual data attributes -->
<div data-bs-restaurant="<%= @restaurant.id %>">

<!-- NEW: Helper method -->
<div <%= restaurant_context_data %>>
```

## Testing

### Unit Tests
```javascript
describe('RestaurantContext', () => {
  it('detects restaurant ID from URL', () => {
    window.history.pushState({}, '', '/restaurants/123/menus');
    expect(RestaurantContext.getRestaurantId()).toBe('123');
  });
  
  it('falls back to data attributes', () => {
    document.body.innerHTML = '<div data-restaurant-id="456"></div>';
    expect(RestaurantContext.getRestaurantId()).toBe('456');
  });
});
```

### Integration Tests
```ruby
# Test helper methods
it 'provides restaurant context data' do
  restaurant = create(:restaurant, id: 123)
  assign(:restaurant, restaurant)
  
  data = helper.restaurant_context_data
  expect(data['data-restaurant-id']).to eq(123)
end
```

## Troubleshooting

### Common Issues

1. **Restaurant ID not detected**
   - Check URL structure matches expected patterns
   - Verify data attributes are correctly set
   - Use debug info to see detection results

2. **Performance issues**
   - Check cache hit rates
   - Verify observers are properly cleaned up
   - Monitor DOM query frequency

3. **Context not updating**
   - Ensure URL change detection is working
   - Check observer notifications
   - Verify cache is being cleared on navigation

### Debug Commands

```javascript
// Get comprehensive debug information
console.log(window.RestaurantContext.getDebugInfo());

// Force refresh context
window.RestaurantContext.refresh();

// Clear all cached data
window.RestaurantContext.clearCache();
```

## Future Enhancements

1. **Multi-restaurant support** - Handle multiple restaurant contexts
2. **Context validation** - Verify restaurant access permissions
3. **Analytics integration** - Track context detection success rates
4. **Performance monitoring** - Monitor detection performance metrics

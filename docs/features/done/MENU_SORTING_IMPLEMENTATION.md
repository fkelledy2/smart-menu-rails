# Menu Sorting Implementation

## Overview
Implemented drag-and-drop sorting for menus with automatic backend sequence updates.

## Changes Made

### 1. View Updates (`app/views/restaurants/sections/_menus_2025.html.erb`)

#### Layout Changes
- **Converted from grid to single-column layout**
  - Changed from multi-column grid (`grid-template-columns: repeat(auto-fill, minmax(320px, 1fr))`)
  - Now uses flex column layout for consistent single-column display
  
#### Drag-and-Drop Integration
- **Added Stimulus sortable controller** with data attributes:
  ```erb
  <div class="menus-list" 
       data-controller="sortable"
       data-sortable-url-value="<%= update_sequence_restaurant_menus_path(restaurant) %>"
       data-sortable-handle-value=".drag-handle">
  ```

- **Added drag handles to each menu card**:
  ```erb
  <div class="drag-handle" title="Drag to reorder">
    <i class="bi bi-grip-vertical"></i>
  </div>
  ```

- **Added sortable ID to each menu**:
  ```erb
  <div class="menu-card" data-sortable-id="<%= menu.id %>">
  ```

#### CSS Changes
- Single-column flex layout
- Drag handle styling with hover effects
- Sortable ghost and drag states for visual feedback
- Proper menu card structure with header content wrapper

### 2. Backend Implementation

#### Route (`config/routes.rb`)
Added collection route for sequence updates:
```ruby
resources :menus do
  collection do
    patch :update_sequence
  end
  # ... other nested resources
end
```

Route: `PATCH /restaurants/:restaurant_id/menus/update_sequence`

#### Controller Action (`app/controllers/menus_controller.rb`)
```ruby
def update_sequence
  authorize Menu.new(restaurant: @restaurant)
  
  order = params[:order] || []
  
  ActiveRecord::Base.transaction do
    order.each do |item|
      menu = @restaurant.menus.find(item[:id])
      menu.update_column(:sequence, item[:sequence])
    end
  end
  
  render json: { status: 'success' }, status: :ok
rescue ActiveRecord::RecordNotFound => e
  render json: { status: 'error', message: 'Menu not found' }, status: :not_found
rescue StandardError => e
  render json: { status: 'error', message: e.message }, status: :unprocessable_entity
end
```

**Features:**
- Authorization check using Pundit
- Transaction for atomicity
- Bulk update using `update_column` for performance
- Proper error handling with JSON responses

#### Authorization
- Added `update_sequence` to `verify_authorized` exceptions
- Manual authorization check in the action

### 3. JavaScript (Already Existed)

The Stimulus sortable controller (`app/javascript/controllers/sortable_controller.js`) was already in place:
- Loads SortableJS from CDN
- Handles drag events
- Auto-saves new order via PATCH request
- Shows success/error indicators

## How It Works

1. **User drags a menu** using the drag handle (⋮⋮ icon)
2. **SortableJS updates** the DOM order visually
3. **Sortable controller fires** the `onEnd` event
4. **JavaScript collects** new order with IDs and sequence numbers
5. **PATCH request sent** to `/restaurants/:restaurant_id/menus/update_sequence`
6. **Backend updates** all menu sequence values in a transaction
7. **Success indicator** shows briefly to confirm save

## Database Impact

- Updates the `sequence` column in the `menus` table
- Uses `update_column` to bypass validations and callbacks for performance
- Wrapped in transaction for data integrity

## UI/UX Features

- ✅ Single-column layout for easier scanning
- ✅ Visible drag handles indicate draggability
- ✅ Smooth animations during drag
- ✅ Ghost effect shows original position
- ✅ Cursor changes to "grabbing" during drag
- ✅ Auto-save eliminates need for save button
- ✅ Visual feedback confirms successful save

## Testing

To test the implementation:

1. Navigate to `http://localhost:3000/restaurants/1/edit?section=menus`
2. Hover over a menu card drag handle (should turn darker)
3. Click and drag a menu up or down
4. Release to drop
5. Check console for "New order" log and success response
6. Refresh page to verify order persists

## Future Enhancements

Potential improvements:
- Add keyboard shortcuts for reordering (↑/↓ arrows)
- Add visual numbering to show sequence
- Implement undo/redo functionality
- Add batch operations (move to top/bottom)

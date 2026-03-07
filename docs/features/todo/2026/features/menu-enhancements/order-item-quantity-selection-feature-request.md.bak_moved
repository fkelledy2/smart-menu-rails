# Order Item Quantity Selection Feature Request

## 📋 **Feature Overview**

**Feature Name**: Order Item Quantity Selection
**Request Type**: User Experience Enhancement
**Priority**: High
**Requested By**: Customer Experience & Operations Team
**Date**: October 11, 2025

## 🎯 **User Story**

> **As a customer or an employee when I add an item to an order, I would like to be able to select the quantity of this item to add to the order (i.e. 2 spaghetti carbonaras), rather than having to add each item individually.**

## 📝 **Detailed Requirements**

### **Primary User Stories**
- [ ] **As a customer**, I want to select quantity when adding menu items so I can order multiple of the same item quickly
- [x] **As a server**, I want to input quantities for customer orders so I can take orders more efficiently ✅ *Staff view: `quick_add_controller.js` stepper on `_showMenuitemStaff.erb`*
- [ ] **As a customer**, I want to modify quantities in my cart so I can adjust my order before confirming
- [ ] **As a manager**, I want to see quantity-based analytics so I can understand popular item volumes
- [ ] **As kitchen staff**, I want to see clear quantities on orders so I can prepare the correct amounts

### **Functional Requirements**

#### **Core Functionality**
- [x] **Quantity Input**: Number input field (1-99) when adding items to order ✅ *Staff view only — `quick_add_controller.js` stepper (1-99 range). Customer view still has single-add button.*
- [x] **Default Quantity**: Default to 1, but allow easy modification ✅ *Staff stepper defaults to 1, resets after add.*
- [ ] **Quantity Validation**: Prevent invalid quantities (0, negative, excessive) ⚠️ *Client-side only (JS clamping). No server-side `quantity` column or model validation — staff flow loops N POST requests creating N separate `ordritem` rows.*
- [ ] **Cart Management**: Update quantities in cart without removing/re-adding items ❌ *Not implemented. Cart (`_cart_bottom_sheet.html.erb`) lists items 1:1 with individual remove buttons. No qty grouping or inline qty modification.*
- [ ] **Price Calculation**: Automatically calculate total price based on quantity ❌ *No line-level qty × price — each `ordritem` has its own `ordritemprice`. Totals work correctly because N rows sum naturally.*
- [ ] **Inventory Awareness**: Check availability for requested quantities ❌ *Not implemented.*

#### **User Interface Requirements**
- [ ] **Menu Item Selection**
  - [x] Quantity selector prominently displayed ✅ *Staff view only — vertical stepper beside each item in `_showMenuitemStaff.erb`*
  - [x] Plus/minus buttons for easy adjustment ✅ *Staff view — `quick-add#increment` / `quick-add#decrement` actions*
  - [ ] Direct number input for large quantities ❌ *Stepper only, no direct numeric input*
  - [x] Visual feedback for quantity changes ✅ *Staff view — qty badge updates, decrement disables at 1*

- [ ] **Shopping Cart Display**
  - [ ] Clear quantity display for each item ❌ *Items shown 1:1, no grouping by menuitem. "2× Carbonara" not displayed.*
  - [ ] Easy quantity modification in cart ❌ *Only remove button per item, no +/- in cart.*
  - [ ] Subtotal calculation per item line ❌ *Each row shows its own price, no qty × unit_price line.*
  - [x] Total order calculation ✅ *Works correctly — sum of all `ordritemprice` values.*

- [ ] **Order Confirmation**
  - [ ] Quantity clearly shown in order summary ❌ *Items listed individually, not grouped.*
  - [ ] Line-item pricing with quantities ❌
  - [x] Final total calculation ✅ *Gross total works correctly via sum of individual items.*

## 🏗️ **Technical Implementation**

### **Database Schema Updates**
```ruby
# Update existing order_items table
class AddQuantityToOrderItems < ActiveRecord::Migration[7.2]
  def change
    add_column :order_items, :quantity, :integer, default: 1, null: false
    add_column :order_items, :unit_price, :decimal, precision: 8, scale: 2

    # Update existing records
    OrderItem.update_all(quantity: 1)

    # Add constraints
    add_check_constraint :order_items, "quantity > 0", name: "quantity_positive"
    add_check_constraint :order_items, "quantity <= 99", name: "quantity_reasonable"

    add_index :order_items, [:ordr_id, :menu_item_id, :quantity]
  end
end
```

### **Model Updates**
```ruby
# app/models/order_item.rb
class OrderItem < ApplicationRecord
  belongs_to :ordr
  belongs_to :menu_item

  validates :quantity, presence: true,
                      numericality: {
                        greater_than: 0,
                        less_than_or_equal_to: 99,
                        only_integer: true
                      }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }

  before_validation :set_unit_price, on: :create
  before_save :calculate_total_price

  scope :by_quantity, ->(qty) { where(quantity: qty) }
  scope :high_quantity, -> { where('quantity >= ?', 5) }

  def total_price
    (unit_price || 0) * (quantity || 1)
  end

  def increase_quantity(amount = 1)
    self.quantity += amount
    calculate_total_price
    save
  end

  def decrease_quantity(amount = 1)
    new_quantity = quantity - amount
    if new_quantity <= 0
      destroy
    else
      self.quantity = new_quantity
      calculate_total_price
      save
    end
  end

  private

  def set_unit_price
    self.unit_price = menu_item.price if menu_item
  end

  def calculate_total_price
    self.price = total_price
  end
end

# app/models/ordr.rb - Update existing model
class Ordr < ApplicationRecord
  has_many :order_items, dependent: :destroy

  def total_items_count
    order_items.sum(:quantity)
  end

  def total_price_with_quantities
    order_items.sum { |item| item.total_price }
  end

  def add_item_with_quantity(menu_item, quantity = 1)
    existing_item = order_items.find_by(menu_item: menu_item)

    if existing_item
      existing_item.increase_quantity(quantity)
    else
      order_items.create!(
        menu_item: menu_item,
        quantity: quantity,
        unit_price: menu_item.price
      )
    end
  end
end
```

### **Controller Updates**
```ruby
# app/controllers/order_items_controller.rb
class OrderItemsController < ApplicationController
  before_action :set_order_item, only: [:show, :update, :destroy]
  before_action :set_order, only: [:create, :update_quantity]

  def create
    @order_item = @order.order_items.build(order_item_params)

    # Check for existing item and merge quantities
    existing_item = @order.order_items.find_by(menu_item: @order_item.menu_item)

    if existing_item
      existing_item.increase_quantity(@order_item.quantity)
      @order_item = existing_item
    else
      @order_item.save
    end

    respond_to do |format|
      if @order_item.persisted?
        format.json { render json: order_response_data, status: :created }
        format.html { redirect_to @order, notice: 'Item added successfully.' }
      else
        format.json { render json: @order_item.errors, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update_quantity
    @order_item = @order.order_items.find(params[:id])
    new_quantity = params[:quantity].to_i

    if new_quantity <= 0
      @order_item.destroy
      message = 'Item removed from order.'
    else
      @order_item.update(quantity: new_quantity)
      message = 'Quantity updated successfully.'
    end

    respond_to do |format|
      format.json { render json: order_response_data }
      format.html { redirect_to @order, notice: message }
    end
  end

  private

  def order_item_params
    params.require(:order_item).permit(:menu_item_id, :quantity, :special_instructions)
  end

  def order_response_data
    {
      order_item: @order_item,
      order_total: @order.total_price_with_quantities,
      items_count: @order.total_items_count
    }
  end
end
```

## 🎨 **User Interface Design**

### **Menu Item Card with Quantity Selector**
```erb
<!-- app/views/menu_items/_item_card.html.erb -->
<div class="menu-item-card" data-controller="quantity-selector" data-menu-item-id="<%= menu_item.id %>">
  <div class="item-info">
    <h5><%= menu_item.name %></h5>
    <p class="description"><%= menu_item.description %></p>
    <div class="price">$<%= menu_item.price %></div>
  </div>

  <div class="quantity-controls">
    <label class="form-label">Quantity:</label>
    <div class="quantity-input-group">
      <button type="button" class="btn btn-outline-secondary btn-sm"
              data-action="click->quantity-selector#decrease">
        <i class="fas fa-minus"></i>
      </button>

      <input type="number"
             class="form-control quantity-input"
             value="1"
             min="1"
             max="99"
             data-quantity-selector-target="input"
             data-action="change->quantity-selector#updateTotal">

      <button type="button" class="btn btn-outline-secondary btn-sm"
              data-action="click->quantity-selector#increase">
        <i class="fas fa-plus"></i>
      </button>
    </div>

    <div class="item-total">
      Total: $<span data-quantity-selector-target="total"><%= menu_item.price %></span>
    </div>
  </div>

  <button class="btn btn-primary add-to-order-btn"
          data-action="click->quantity-selector#addToOrder">
    Add to Order
  </button>
</div>
```

### **Shopping Cart with Quantity Management**
```erb
<!-- app/views/ordrs/_cart_items.html.erb -->
<div class="cart-items" data-controller="cart-manager">
  <% @order.order_items.each do |item| %>
    <div class="cart-item" data-cart-manager-target="item" data-item-id="<%= item.id %>">
      <div class="item-details">
        <h6><%= item.menu_item.name %></h6>
        <div class="unit-price">$<%= item.unit_price %> each</div>
      </div>

      <div class="quantity-controls">
        <button type="button" class="btn btn-sm btn-outline-secondary"
                data-action="click->cart-manager#decreaseQuantity"
                data-item-id="<%= item.id %>">
          <i class="fas fa-minus"></i>
        </button>

        <span class="quantity-display"><%= item.quantity %></span>

        <button type="button" class="btn btn-sm btn-outline-secondary"
                data-action="click->cart-manager#increaseQuantity"
                data-item-id="<%= item.id %>">
          <i class="fas fa-plus"></i>
        </button>
      </div>

      <div class="line-total">
        $<span data-cart-manager-target="lineTotal"><%= item.total_price %></span>
      </div>

      <button type="button" class="btn btn-sm btn-outline-danger"
              data-action="click->cart-manager#removeItem"
              data-item-id="<%= item.id %>">
        <i class="fas fa-trash"></i>
      </button>
    </div>
  <% end %>

  <div class="cart-summary">
    <div class="total-items">
      Total Items: <span data-cart-manager-target="totalItems"><%= @order.total_items_count %></span>
    </div>
    <div class="order-total">
      Order Total: $<span data-cart-manager-target="orderTotal"><%= @order.total_price_with_quantities %></span>
    </div>
  </div>
</div>
```

## 📱 **JavaScript Implementation**

### **Quantity Selector Stimulus Controller**
```javascript
// app/javascript/controllers/quantity_selector_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "total"]
  static values = {
    unitPrice: Number,
    menuItemId: Number
  }

  connect() {
    this.updateTotal()
  }

  increase() {
    const currentValue = parseInt(this.inputTarget.value)
    if (currentValue < 99) {
      this.inputTarget.value = currentValue + 1
      this.updateTotal()
    }
  }

  decrease() {
    const currentValue = parseInt(this.inputTarget.value)
    if (currentValue > 1) {
      this.inputTarget.value = currentValue - 1
      this.updateTotal()
    }
  }

  updateTotal() {
    const quantity = parseInt(this.inputTarget.value) || 1
    const total = (this.unitPriceValue * quantity).toFixed(2)
    this.totalTarget.textContent = total
  }

  async addToOrder() {
    const quantity = parseInt(this.inputTarget.value)

    try {
      const response = await fetch('/order_items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          order_item: {
            menu_item_id: this.menuItemIdValue,
            quantity: quantity
          }
        })
      })

      if (response.ok) {
        const data = await response.json()
        this.updateCartDisplay(data)
        this.showSuccessMessage(`Added ${quantity} item(s) to order`)
        this.resetQuantity()
      }
    } catch (error) {
      this.showErrorMessage('Failed to add item to order')
    }
  }

  resetQuantity() {
    this.inputTarget.value = 1
    this.updateTotal()
  }

  updateCartDisplay(data) {
    // Update cart counter, total, etc.
    const cartCounter = document.querySelector('.cart-counter')
    if (cartCounter) {
      cartCounter.textContent = data.items_count
    }

    const orderTotal = document.querySelector('.order-total')
    if (orderTotal) {
      orderTotal.textContent = `$${data.order_total}`
    }
  }

  showSuccessMessage(message) {
    // Show toast notification or update UI
    console.log(message)
  }

  showErrorMessage(message) {
    // Show error notification
    console.error(message)
  }
}
```

### **Cart Manager Stimulus Controller**
```javascript
// app/javascript/controllers/cart_manager_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "lineTotal", "totalItems", "orderTotal"]

  async increaseQuantity(event) {
    const itemId = event.currentTarget.dataset.itemId
    await this.updateQuantity(itemId, 1)
  }

  async decreaseQuantity(event) {
    const itemId = event.currentTarget.dataset.itemId
    await this.updateQuantity(itemId, -1)
  }

  async updateQuantity(itemId, change) {
    const itemElement = this.element.querySelector(`[data-item-id="${itemId}"]`)
    const quantityDisplay = itemElement.querySelector('.quantity-display')
    const currentQuantity = parseInt(quantityDisplay.textContent)
    const newQuantity = currentQuantity + change

    try {
      const response = await fetch(`/order_items/${itemId}/update_quantity`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ quantity: newQuantity })
      })

      if (response.ok) {
        const data = await response.json()

        if (newQuantity <= 0) {
          itemElement.remove()
        } else {
          quantityDisplay.textContent = newQuantity
          this.updateLineTotal(itemElement, data.order_item)
        }

        this.updateOrderTotals(data)
      }
    } catch (error) {
      console.error('Failed to update quantity:', error)
    }
  }

  async removeItem(event) {
    const itemId = event.currentTarget.dataset.itemId
    await this.updateQuantity(itemId, -999) // Force removal
  }

  updateLineTotal(itemElement, orderItem) {
    const lineTotalElement = itemElement.querySelector('[data-cart-manager-target="lineTotal"]')
    lineTotalElement.textContent = orderItem.total_price.toFixed(2)
  }

  updateOrderTotals(data) {
    this.totalItemsTarget.textContent = data.items_count
    this.orderTotalTarget.textContent = data.order_total.toFixed(2)
  }
}
```

## 🔐 **Security & Validation**

### **Input Validation**
```ruby
# app/models/order_item.rb - Enhanced validations
class OrderItem < ApplicationRecord
  validates :quantity, presence: true,
                      numericality: {
                        greater_than: 0,
                        less_than_or_equal_to: 99,
                        only_integer: true
                      }

  validate :reasonable_quantity_for_item_type
  validate :inventory_availability

  private

  def reasonable_quantity_for_item_type
    return unless menu_item && quantity

    # Different limits for different item types
    max_quantity = case menu_item.category
                  when 'beverage' then 20
                  when 'appetizer' then 10
                  when 'entree' then 8
                  when 'dessert' then 6
                  else 99
                  end

    if quantity > max_quantity
      errors.add(:quantity, "cannot exceed #{max_quantity} for #{menu_item.category} items")
    end
  end

  def inventory_availability
    return unless menu_item&.track_inventory? && quantity

    if menu_item.available_quantity < quantity
      errors.add(:quantity, "only #{menu_item.available_quantity} available")
    end
  end
end
```

## 📊 **Analytics & Reporting**

### **Quantity-Based Metrics**
```ruby
# app/models/analytics/order_analytics.rb
class Analytics::OrderAnalytics
  def self.popular_quantities
    OrderItem.group(:menu_item_id, :quantity)
             .joins(:menu_item)
             .select('menu_items.name, quantity, COUNT(*) as frequency')
             .order('frequency DESC')
  end

  def self.high_quantity_orders
    Ordr.joins(:order_items)
        .where('order_items.quantity >= ?', 5)
        .includes(:order_items, :menu_items)
  end

  def self.average_quantity_per_item
    OrderItem.group(:menu_item_id)
             .joins(:menu_item)
             .average(:quantity)
  end

  def self.quantity_distribution
    OrderItem.group(:quantity).count
  end
end
```

## 🧪 **Testing Strategy**

### **Model Tests**
```ruby
# test/models/order_item_test.rb
class OrderItemTest < ActiveSupport::TestCase
  test "should validate quantity is positive" do
    item = OrderItem.new(quantity: 0)
    assert_not item.valid?
    assert_includes item.errors[:quantity], "must be greater than 0"
  end

  test "should calculate total price correctly" do
    item = OrderItem.new(quantity: 3, unit_price: 12.50)
    assert_equal 37.50, item.total_price
  end

  test "should increase quantity and recalculate price" do
    item = order_items(:one)
    original_quantity = item.quantity
    item.increase_quantity(2)

    assert_equal original_quantity + 2, item.quantity
    assert_equal item.unit_price * item.quantity, item.price
  end
end
```

### **Integration Tests**
```ruby
# test/integration/quantity_selection_test.rb
class QuantitySelectionTest < ActionDispatch::IntegrationTest
  test "customer can add multiple items with quantity" do
    menu_item = menu_items(:pasta)

    post order_items_path, params: {
      order_item: {
        menu_item_id: menu_item.id,
        quantity: 3
      }
    }, as: :json

    assert_response :created

    response_data = JSON.parse(response.body)
    assert_equal 3, response_data['order_item']['quantity']
    assert_equal menu_item.price * 3, response_data['order_item']['price']
  end
end
```

## 🚀 **Implementation Phases**

### **Phase 1: Backend Foundation (1 week)**
- Database schema updates
- Model validations and methods
- Basic API endpoints

### **Phase 2: Frontend Implementation (1-2 weeks)**
- Quantity selector UI components
- Cart management interface
- JavaScript controllers

### **Phase 3: Integration & Testing (1 week)**
- End-to-end testing
- Performance optimization
- Bug fixes and refinements

### **Phase 4: Analytics & Reporting (1 week)**
- Quantity-based analytics
- Reporting dashboard updates
- Business intelligence integration

---

## 🔍 **Implementation Status Review** (2026-03-06)

### What Has Been Completed

| Area | Status | Notes |
|---|---|---|
| **Staff quantity stepper UI** | ✅ Done | `quick_add_controller.js` Stimulus controller with +/- buttons (1-99 range) |
| **Staff menu item wiring** | ✅ Done | `_showMenuitemStaff.erb` — each item card has `data-controller="quick-add"` with vertical stepper |
| **Staff add-item flow** | ✅ Done | `ordr_commons.js` reads `window.__quickAddQty` and loops N POST calls to `/restaurants/:id/ordritems` |
| **Stepper CSS (light + dark)** | ✅ Done | `_smartmenu_mobile.scss` + `_dark_mode.scss` — both horizontal and vertical stepper variants |
| **Order total calculation** | ✅ Done | Works correctly — each `ordritem` row has its own price, sum = gross total |

### What Has NOT Been Completed

| Area | Status | Blocker / Notes |
|---|---|---|
| **Database `quantity` column** | ❌ Not done | `ordritems` has no `quantity` field. Staff flow creates N separate rows instead. |
| **Model validations** | ❌ Not done | `Ordritem` model has no quantity attribute, no `unit_price` field |
| **Customer view quantity selector** | ❌ Not done | `_showMenuitem.erb` has a plain `+` button, no stepper. The add-item modal (`_modal_footer_add_item.erb`) has no quantity controls. |
| **Cart quantity display** | ❌ Not done | `_cart_bottom_sheet.html.erb` lists items 1:1 — no grouping by menuitem, no "2× Carbonara" display |
| **Cart quantity modification** | ❌ Not done | Only individual remove buttons, no +/- adjustment in cart |
| **Kitchen/station qty grouping** | ❌ Not done | Kitchen/station dashboards show items individually |
| **Quantity-based analytics** | ❌ Not done | No `OrderAnalytics` class, no quantity reporting |
| **Inventory qty checks** | ❌ Not done | No validation against available stock |
| **API endpoint for qty update** | ❌ Not done | No `update_quantity` action on `OrderItemsController` |

### Current Architecture (How Staff Qty Works Today)

```
 Staff taps +/- stepper  →  quick_add_controller.js stores qty in window.__quickAddQty
 Staff taps item name    →  storeQty() fires, modal opens
 Staff confirms in modal →  ordr_commons.js reads __quickAddQty
                         →  loops N times: POST /restaurants/:id/ordritems
                         →  creates N separate ordritem rows (each with line_key UUID)
```

This is a **presentation-layer-only** implementation. The backend has no concept of quantity — it just receives N individual create requests.

---

## 📋 **Closing Plan**

### Decision: Schema-first vs. Presentation-only

Two approaches exist to close out this feature:

**Option A — Schema-first (Recommended):** Add a `quantity` column to `ordritems`, consolidate duplicate rows, and build proper cart grouping. This is the approach described in the original spec.

**Option B — Presentation-only:** Keep 1-row-per-unit in the DB but group items visually in the cart and kitchen views. Simpler DB-wise, but loses the ability to do proper qty-based analytics and makes cart modification harder.

### Recommended Plan (Option A)

#### Phase 1: Backend Foundation (3-4 days)

1. **Migration**: Add `quantity` (integer, default 1, not null) to `ordritems`
   - Backfill existing rows with `quantity: 1`
   - Add check constraint `quantity > 0 AND quantity <= 99`
   - Reference: `db/schema.rb` → `ordritems` table (DATA_MODEL.md §3.4)

2. **Model updates** on `Ordritem` (`app/models/ordritem.rb`):
   - Add `validates :quantity, numericality: { greater_than: 0, less_than_or_equal_to: 99, only_integer: true }`
   - Add `total_price` method: `ordritemprice * quantity`
   - Add `increase_quantity(n)` / `decrease_quantity(n)` methods

3. **Controller updates** on `OrdritemsController` (`app/controllers/ordritems_controller.rb`):
   - Accept `quantity` in strong params
   - Add `update_quantity` action
   - On create: if matching `ordritem` (same `menuitem_id`, `size_name`, status `opened`) exists, increment its quantity instead of creating a new row

4. **Update `ordr_commons.js`** staff add-item flow:
   - Instead of looping N POST calls, send a single POST with `quantity: N`
   - Update `__quickAddQty` handling accordingly

5. **Update order total calculations** in `Ordr` model:
   - `runningTotal` / `nett` should respect `quantity * ordritemprice`
   - Reference: SERVICE_MAP.md §5.7 — `OrderEventProjector`

#### Phase 2: Customer View (3-4 days)

6. **Add quantity selector to customer add-item modal**:
   - Add +/- stepper to `_modal_footer_add_item.erb` (or inside modal body)
   - Wire to the existing `addItemToOrderButton` click handler in `ordr_commons.js`
   - Reuse `quick_add_controller.js` or create a simpler inline stepper
   - Reference: `_showMenuitem.erb`, `_showMenuitemHorizontal.html.erb`

7. **Cart quantity display and modification** in `_cart_bottom_sheet.html.erb`:
   - Group items by `menuitem_id` + `size_name` in the "Selected" section
   - Show "2× Carbonara" format with qty badge
   - Add +/- buttons per grouped line → call `PATCH /ordritems/:id` with new quantity
   - Update `state_controller.js` dynamic cart rendering to match

8. **Cart total display**:
   - Show unit price × qty = line total per grouped row
   - Reference: `order_totals_controller.js` (SERVICE_MAP.md §8)

#### Phase 3: Kitchen & Integration (2-3 days)

9. **Kitchen/station dashboard qty display**:
   - Group duplicate items and show "×2" badge on tickets
   - Reference: `kitchen_dashboard.js`, `station_dashboard.js`, `OrdrStationTicketService` (SERVICE_MAP.md §5.7)

10. **ActionCable broadcast updates**:
    - Ensure `OrdrChannel` / `KitchenChannel` payloads include quantity
    - Reference: ARCHITECTURE.md §4.3, SERVICE_MAP.md §3

11. **Tests**:
    - Model tests: quantity validation, `total_price`, `increase/decrease_quantity`
    - Controller tests: create with qty, update_quantity, merge duplicate items
    - System tests: staff stepper → single POST with qty, customer modal qty

#### Phase 4: Analytics & Polish (2-3 days)

12. **Quantity-based analytics**:
    - Add to `dw_orders_mv` materialized view
    - Popular quantities, high-qty orders, avg qty per item
    - Reference: DATA_MODEL.md §3.12, SERVICE_MAP.md §6.5

13. **Inventory awareness** (if `inventoryTracking` enabled):
    - Validate requested qty against `Inventory` stock on create
    - Reference: DATA_MODEL.md — `inventories` table

14. **Polish**:
    - Accessibility (aria labels on stepper)
    - Mobile responsiveness
    - Animation/feedback for qty changes

### Estimated Total: 10-14 days

## 💰 **Business Value**

### **User Experience Benefits**
- [x] **Faster Ordering** - Reduce clicks from 6 to 2 for multiple items ✅ *Staff view only*
- [x] **Reduced Friction** - Eliminate repetitive item selection ✅ *Staff view only*
- [ ] **Clear Pricing** - Transparent quantity-based pricing
- [ ] **Better Cart Management** - Easy quantity adjustments

### **Operational Benefits**
- [x] **Improved Efficiency** - Servers can take orders faster ✅ *Staff stepper implemented*
- [ ] **Better Analytics** - Understand quantity preferences
- [ ] **Inventory Management** - Track high-quantity items
- [ ] **Revenue Insights** - Identify bulk ordering patterns

### **Revenue Impact**
- [ ] **Increased Order Size** - Easier to order multiple items
- [ ] **Reduced Abandonment** - Smoother ordering process
- [ ] **Upselling Opportunities** - Suggest quantity discounts
- [ ] **Customer Satisfaction** - Better user experience

## 📋 **Acceptance Criteria**

### **Functional Requirements**
- [x] Users can select quantity (1-99) when adding items ✅ *Staff view only*
- [x] Quantity defaults to 1 but is easily adjustable ✅ *Staff view only*
- [ ] Cart shows quantities and line totals clearly
- [ ] Quantities can be modified in cart
- [x] Total price updates automatically ✅ *Sum of individual rows works*
- [ ] Invalid quantities are prevented ❌ *No server-side validation*
- [ ] Inventory limits are respected

### **User Experience Requirements**
- [x] Quantity selector is intuitive and accessible ✅ *Staff view only*
- [x] Plus/minus buttons work smoothly ✅ *Staff view only*
- [ ] Direct number input is supported
- [x] Visual feedback for quantity changes ✅ *Staff view only*
- [x] Mobile-responsive design ✅ *Staff stepper is responsive*
- [x] Fast response times (<500ms) ✅ *Stepper is instant, POST is fast*

This feature will significantly improve the ordering experience for both customers and employees by eliminating the need to add items individually when ordering multiple quantities of the same item.

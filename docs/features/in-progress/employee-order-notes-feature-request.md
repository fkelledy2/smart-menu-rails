# Employee Order Notes Feature Request

## 📋 **Feature Overview**

**Feature Name**: Employee Order Notes and Special Instructions
**Request Type**: New Feature Enhancement
**Priority**: Medium-High
**Requested By**: Restaurant Operations Team
**Date**: October 11, 2025

## 🎯 **User Story**

> **As an employee of a restaurant, I would like to be able to add notes and comments to an order containing special instructions about the order, so that I can communicate important preparation details, dietary restrictions, customer preferences, and operational notes to kitchen staff and other team members.**

## 📝 **Detailed Requirements**

### **Primary User Stories**
- [ ] **As a server**, I want to add customer dietary restrictions to an order so the kitchen knows about allergies
- [ ] **As a manager**, I want to add operational notes about order timing so staff can coordinate delivery
- [ ] **As kitchen staff**, I want to see all order notes in one place so I don't miss important instructions
- [ ] **As a server**, I want to add special preparation instructions so the kitchen can customize the order
- [ ] **As a manager**, I want to track who added notes and when for accountability

### **Functional Requirements**

#### **Core Functionality**
- [ ] **Add Notes**: Employees can add multiple notes to any order
- [ ] **Edit Notes**: Employees can edit their own notes within a time window
- [ ] **View Notes**: All team members can view order notes in real-time
- [ ] **Note Categories**: Different types of notes (dietary, preparation, timing, general)
- [ ] **Note Visibility**: Notes visible in kitchen display, mobile app, and management dashboard

#### **Note Types and Categories**
- [ ] **Dietary Restrictions** 🚨
  - [ ] Allergies (nuts, gluten, dairy, etc.)
  - [ ] Dietary preferences (vegan, vegetarian, keto)
  - [ ] Medical restrictions
  - [ ] Priority: High visibility

- [ ] **Preparation Instructions** 👨‍🍳
  - [ ] Cooking preferences (well-done, rare, etc.)
  - [ ] Ingredient modifications (no onions, extra sauce)
  - [ ] Plating instructions
  - [ ] Temperature preferences

- [ ] **Timing Instructions** ⏰
  - [ ] Rush orders
  - [ ] Delayed preparation requests
  - [ ] Coordination with other orders
  - [ ] Delivery timing

- [ ] **Customer Service Notes** 💬
  - [ ] Special occasions (birthday, anniversary)
  - [ ] Customer preferences from previous visits
  - [ ] Complaint resolution notes
  - [ ] VIP customer indicators

- [ ] **Operational Notes** 🔧
  - [ ] Staff coordination messages
  - [ ] Inventory alerts
  - [ ] Equipment considerations
  - [ ] Quality control notes

## 🏗️ **Technical Implementation**

### **Database Schema**
```ruby
# New table: order_notes
class CreateOrderNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :order_notes do |t|
      t.references :ordr, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.text :content, null: false
      t.string :category, null: false # enum: dietary, preparation, timing, customer_service, operational
      t.integer :priority, default: 0 # enum: low, medium, high, urgent
      t.boolean :visible_to_kitchen, default: true
      t.boolean :visible_to_servers, default: true
      t.boolean :visible_to_customers, default: false
      t.datetime :expires_at, null: true # for time-sensitive notes
      t.timestamps
    end

    add_index :order_notes, [:ordr_id, :created_at]
    add_index :order_notes, [:category, :priority]
    add_index :order_notes, :employee_id
  end
end
```

### **Model Implementation**
```ruby
# app/models/order_note.rb
class OrderNote < ApplicationRecord
  belongs_to :ordr
  belongs_to :employee

  enum :category, {
    dietary: 0,
    preparation: 1,
    timing: 2,
    customer_service: 3,
    operational: 4
  }

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }

  validates :content, presence: true, length: { minimum: 3, maximum: 500 }
  validates :category, presence: true
  validates :priority, presence: true

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :for_kitchen, -> { where(visible_to_kitchen: true) }
  scope :for_servers, -> { where(visible_to_servers: true) }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def high_priority?
    urgent? || high?
  end
end

# Update app/models/ordr.rb
class Ordr < ApplicationRecord
  has_many :order_notes, dependent: :destroy
  has_many :active_order_notes, -> { active }, class_name: 'OrderNote'
  has_many :kitchen_notes, -> { for_kitchen.active }, class_name: 'OrderNote'
  has_many :urgent_notes, -> { where(priority: [:high, :urgent]).active }, class_name: 'OrderNote'
end

# Update app/models/employee.rb
class Employee < ApplicationRecord
  has_many :order_notes, dependent: :destroy
end
```

### **Controller Implementation**
```ruby
# app/controllers/order_notes_controller.rb
class OrderNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_order
  before_action :set_order_note, only: [:show, :edit, :update, :destroy]

  after_action :verify_authorized
  after_action :verify_policy_scoped, only: [:index]

  def index
    @order_notes = policy_scope(@order.order_notes.includes(:employee)).by_priority
  end

  def create
    @order_note = @order.order_notes.build(order_note_params)
    @order_note.employee = current_employee
    authorize @order_note

    if @order_note.save
      broadcast_order_note_created
      redirect_to restaurant_ordr_path(@restaurant, @order),
                  notice: 'Order note added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @order_note

    if @order_note.update(order_note_params)
      broadcast_order_note_updated
      redirect_to restaurant_ordr_path(@restaurant, @order),
                  notice: 'Order note updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @order_note
    @order_note.destroy
    broadcast_order_note_deleted
    redirect_to restaurant_ordr_path(@restaurant, @order),
                notice: 'Order note removed successfully.'
  end

  private

  def set_order
    @order = @restaurant.ordrs.find(params[:ordr_id])
  end

  def set_order_note
    @order_note = @order.order_notes.find(params[:id])
  end

  def order_note_params
    params.require(:order_note).permit(:content, :category, :priority,
                                       :visible_to_kitchen, :visible_to_servers,
                                       :visible_to_customers, :expires_at)
  end

  def current_employee
    @restaurant.employees.find_by(user: current_user)
  end

  def broadcast_order_note_created
    OrderNotesChannel.broadcast_to(@order, {
      action: 'note_created',
      note: @order_note,
      employee: @order_note.employee.name
    })
  end
end
```

### **Real-time Updates**
```ruby
# app/channels/order_notes_channel.rb
class OrderNotesChannel < ApplicationCable::Channel
  def subscribed
    order = Ordr.find(params[:order_id])
    stream_for order if can_access_order?(order)
  end

  private

  def can_access_order?(order)
    current_user.restaurants.include?(order.restaurant)
  end
end
```

## 🎨 **User Interface Design**

### **Order Notes Section**
```erb
<!-- app/views/ordrs/_order_notes.html.erb -->
<div class="order-notes-section" data-controller="order-notes" data-order-id="<%= @order.id %>">
  <div class="notes-header">
    <h4>Order Notes & Instructions</h4>
    <button class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#addNoteModal">
      <i class="fas fa-plus"></i> Add Note
    </button>
  </div>

  <div class="notes-list">
    <% @order.active_order_notes.by_priority.each do |note| %>
      <div class="note-card priority-<%= note.priority %> category-<%= note.category %>">
        <div class="note-header">
          <span class="note-category badge bg-<%= category_color(note.category) %>">
            <%= note.category.humanize %>
          </span>
          <span class="note-priority badge bg-<%= priority_color(note.priority) %>">
            <%= note.priority.humanize %>
          </span>
          <small class="text-muted">
            by <%= note.employee.name %> • <%= time_ago_in_words(note.created_at) %> ago
          </small>
        </div>
        <div class="note-content">
          <%= simple_format(note.content) %>
        </div>
        <% if note.expires_at %>
          <div class="note-expiry">
            <i class="fas fa-clock"></i> Expires <%= time_ago_in_words(note.expires_at) %>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

### **Add Note Modal**
```erb
<!-- app/views/ordrs/_add_note_modal.html.erb -->
<div class="modal fade" id="addNoteModal">
  <div class="modal-dialog">
    <div class="modal-content">
      <%= form_with model: [@restaurant, @order, OrderNote.new],
                    local: true, class: "modal-form" do |form| %>
        <div class="modal-header">
          <h5 class="modal-title">Add Order Note</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <%= form.label :category, class: "form-label" %>
            <%= form.select :category,
                options_for_select([
                  ['🚨 Dietary Restrictions', 'dietary'],
                  ['👨‍🍳 Preparation Instructions', 'preparation'],
                  ['⏰ Timing Instructions', 'timing'],
                  ['💬 Customer Service', 'customer_service'],
                  ['🔧 Operational Notes', 'operational']
                ]),
                { prompt: 'Select note type...' },
                { class: "form-select" } %>
          </div>

          <div class="mb-3">
            <%= form.label :priority, class: "form-label" %>
            <%= form.select :priority,
                options_for_select([
                  ['Low Priority', 'low'],
                  ['Medium Priority', 'medium'],
                  ['High Priority', 'high'],
                  ['🚨 Urgent', 'urgent']
                ]),
                { selected: 'medium' },
                { class: "form-select" } %>
          </div>

          <div class="mb-3">
            <%= form.label :content, "Note Content", class: "form-label" %>
            <%= form.text_area :content,
                class: "form-control",
                rows: 4,
                placeholder: "Enter special instructions, dietary restrictions, or other important notes..." %>
          </div>

          <div class="row">
            <div class="col-md-4">
              <div class="form-check">
                <%= form.check_box :visible_to_kitchen, { checked: true }, "true", "false" %>
                <%= form.label :visible_to_kitchen, "Kitchen", class: "form-check-label" %>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-check">
                <%= form.check_box :visible_to_servers, { checked: true }, "true", "false" %>
                <%= form.label :visible_to_servers, "Servers", class: "form-check-label" %>
              </div>
            </div>
            <div class="col-md-4">
              <div class="form-check">
                <%= form.check_box :visible_to_customers, {}, "true", "false" %>
                <%= form.label :visible_to_customers, "Customers", class: "form-check-label" %>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
          <%= form.submit "Add Note", class: "btn btn-primary" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

## 📱 **Mobile Integration**

### **Kitchen Display Updates**
- [ ] **High-priority notes** displayed prominently on kitchen screens
- [ ] **Color-coded categories** for quick visual identification
- [ ] **Real-time updates** when notes are added or modified
- [ ] **Audio alerts** for urgent dietary restriction notes

### **Server Mobile App**
- [ ] **Quick note templates** for common instructions
- [ ] **Voice-to-text** note input for busy environments
- [ ] **Push notifications** when kitchen adds preparation notes
- [ ] **Order history** showing previous customer preferences

## 🔐 **Security & Permissions**

### **Access Control**
```ruby
# app/policies/order_note_policy.rb
class OrderNotePolicy < ApplicationPolicy
  def index?
    user_is_restaurant_employee?
  end

  def create?
    user_is_restaurant_employee?
  end

  def update?
    user_is_restaurant_employee? && (record.employee.user == user || user_is_manager?)
  end

  def destroy?
    user_is_restaurant_employee? && (record.employee.user == user || user_is_manager?)
  end

  private

  def user_is_restaurant_employee?
    record.ordr.restaurant.employees.exists?(user: user)
  end

  def user_is_manager?
    employee = record.ordr.restaurant.employees.find_by(user: user)
    employee&.manager? || employee&.admin?
  end
end
```

### **Data Privacy**
- [ ] **Employee attribution** - Track who added each note
- [ ] **Edit history** - Maintain audit trail of note changes
- [ ] **Automatic expiry** - Time-sensitive notes auto-expire
- [ ] **Customer visibility** - Control what customers can see

## 📊 **Analytics & Reporting**

### **Metrics to Track**
- [ ] **Note Usage Statistics**
  - [ ] Notes per order average
  - [ ] Most common note categories
  - [ ] Peak note creation times
  - [ ] Employee note activity

- [ ] **Operational Insights**
  - [ ] Orders with dietary restriction notes
  - [ ] Average preparation time for orders with notes
  - [ ] Note category correlation with order modifications
  - [ ] Customer satisfaction for orders with service notes

- [ ] **Quality Control**
  - [ ] Urgent note response times
  - [ ] Note accuracy and usefulness ratings
  - [ ] Kitchen acknowledgment of dietary restrictions
  - [ ] Customer feedback on special instructions

## 🧪 **Testing Strategy**

### **Unit Tests**
- [ ] **Model validations** - Content length, required fields
- [ ] **Associations** - Order, employee relationships
- [ ] **Scopes** - Active notes, priority filtering
- [ ] **Business logic** - Expiry, visibility rules

### **Integration Tests**
- [ ] **Note creation workflow** - Full CRUD operations
- [ ] **Real-time updates** - ActionCable broadcasting
- [ ] **Permission enforcement** - Pundit policy testing
- [ ] **Mobile API** - JSON response validation

### **User Acceptance Tests**
- [ ] **Kitchen workflow** - Note visibility and acknowledgment
- [ ] **Server workflow** - Quick note creation and editing
- [ ] **Manager oversight** - Note monitoring and reporting
- [ ] **Customer experience** - Appropriate note visibility

## 🚀 **Implementation Phases**

### **Phase 1: Core Functionality (2-3 weeks)**
- [ ] Database schema and models
- [ ] Basic CRUD operations
- [ ] Simple UI for adding/viewing notes
- [ ] Basic permission system

### **Phase 2: Enhanced Features (2-3 weeks)**
- [ ] Real-time updates with ActionCable
- [ ] Note categories and priorities
- [ ] Kitchen display integration
- [ ] Mobile-responsive design

### **Phase 3: Advanced Features (2-3 weeks)**
- [ ] Analytics and reporting
- [ ] Note templates and quick actions
- [ ] Voice-to-text integration
- [ ] Customer-facing note visibility

### **Phase 4: Optimization (1-2 weeks)**
- [ ] Performance optimization
- [ ] Advanced search and filtering
- [ ] Automated note suggestions
- [ ] Integration with existing systems

## 💰 **Business Value**

### **Operational Benefits**
- [ ] **Reduced Order Errors** - Clear communication prevents mistakes
- [ ] **Improved Food Safety** - Dietary restrictions prominently displayed
- [ ] **Enhanced Customer Service** - Special requests properly communicated
- [ ] **Staff Coordination** - Better teamwork through shared information

### **Customer Experience**
- [ ] **Personalized Service** - Notes capture customer preferences
- [ ] **Dietary Safety** - Allergy information clearly communicated
- [ ] **Special Occasions** - Birthday/anniversary notes enhance experience
- [ ] **Consistency** - Preferences remembered across visits

### **Revenue Impact**
- [ ] **Reduced Waste** - Fewer remade orders due to miscommunication
- [ ] **Customer Retention** - Better service leads to repeat business
- [ ] **Upselling Opportunities** - Notes can suggest complementary items
- [ ] **Efficiency Gains** - Streamlined kitchen operations

## 📋 **Acceptance Criteria**

### **Functional Requirements**
- [ ] Employees can add notes to any order
- [ ] Notes are categorized (dietary, preparation, timing, etc.)
- [ ] Notes have priority levels (low, medium, high, urgent)
- [ ] Notes update in real-time across all interfaces
- [ ] Kitchen staff can see relevant notes on their displays
- [ ] Managers can view note analytics and reports
- [ ] Notes can be edited within a time window
- [ ] Notes can be set to expire automatically

### **Non-Functional Requirements**
- [ ] Notes load within 2 seconds
- [ ] Real-time updates delivered within 5 seconds
- [ ] Mobile interface works on all devices
- [ ] System handles 100+ concurrent note operations
- [ ] All note operations are logged for audit
- [ ] Notes are backed up with order data

### **User Experience Requirements**
- [ ] Intuitive note creation interface
- [ ] Clear visual distinction between note types
- [ ] Easy-to-read kitchen display format
- [ ] Quick access to common note templates
- [ ] Seamless integration with existing order workflow

## 🔄 **Future Enhancements**

### **Advanced Features**
- [ ] **AI-Powered Suggestions** - Suggest notes based on order patterns
- [ ] **Voice Commands** - "Add dietary note: no nuts"
- [ ] **Photo Attachments** - Visual instructions for complex preparations
- [ ] **Customer Self-Service** - Customers add their own dietary restrictions
- [ ] **Integration with POS** - Sync with existing point-of-sale systems

### **Automation Opportunities**
- [ ] **Smart Templates** - Auto-suggest notes based on menu items
- [ ] **Dietary Scanning** - Automatically flag potential allergens
- [ ] **Preparation Timing** - Calculate prep time based on notes
- [ ] **Quality Scoring** - Rate note usefulness and accuracy

This comprehensive feature request provides a complete roadmap for implementing employee order notes functionality that will significantly enhance restaurant operations, improve customer service, and ensure food safety through better communication of special instructions and dietary restrictions.

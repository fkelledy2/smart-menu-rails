# Bill Splitting Feature Request

## 📋 **Feature Overview**

**Feature Name**: Bill Splitting Among Order Participants
**Priority**: High
**Category**: Payment Processing & Customer Experience
**Estimated Effort**: Large (8-10 weeks)
**Target Release**: Q2 2026

## 🎯 **User Story**

**As a** customer
**I want to** split the bill among guests participating in the current order
**So that** each person can pay their fair share of the meal

**As an** employee
**I want to** ensure that split amounts when combined equal or exceed the total bill amount
**So that** the restaurant receives full payment for the order

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Bill Splitting Interface**
- [ ] **Participant Selection**: Choose which guests participate in bill splitting
- [ ] **Split Methods**: Equal split, custom amounts, or item-based splitting
- [ ] **Real-time Calculation**: Live updates of split amounts as changes are made
- [ ] **Payment Assignment**: Assign payment methods to each participant
- [ ] **Validation System**: Ensure total splits equal or exceed bill amount

#### **2. Split Calculation Methods**
- [ ] **Equal Split**: Divide total amount equally among participants
- [ ] **Custom Split**: Manual amount entry for each participant
- [ ] **Item-Based Split**: Assign specific items to specific participants
- [ ] **Percentage Split**: Split by percentage allocation
- [ ] **Hybrid Split**: Combination of methods (shared items + individual items)

#### **3. Employee Validation Tools**
- [ ] **Split Verification**: Visual confirmation that splits cover full amount
- [ ] **Overpayment Handling**: Manage situations where splits exceed total
- [ ] **Payment Tracking**: Monitor payment status for each participant
- [ ] **Adjustment Interface**: Modify splits if needed before processing
- [ ] **Audit Trail**: Complete record of split decisions and modifications

#### **4. Payment Processing Integration**
- [ ] **Multiple Payment Methods**: Support different payment types per participant
- [ ] **Simultaneous Processing**: Process multiple payments concurrently
- [ ] **Payment Failure Handling**: Manage failed payments in split scenarios
- [ ] **Refund Management**: Handle refunds for overpayments or cancellations
- [ ] **Receipt Generation**: Individual receipts for each participant

### **Secondary Requirements**

#### **5. Advanced Splitting Features**
- [ ] **Tax and Tip Allocation**: Proportional distribution of taxes and tips
- [ ] **Discount Handling**: Apply discounts before or after splitting
- [ ] **Service Charge Distribution**: Handle automatic service charges
- [ ] **Currency Handling**: Support for different currencies and rounding
- [ ] **Split Templates**: Save common splitting patterns for reuse

#### **6. Customer Experience Enhancements**
- [ ] **Mobile-Friendly Interface**: Touch-optimized splitting controls
- [ ] **QR Code Payments**: Individual QR codes for each participant's portion
- [ ] **Payment Notifications**: Real-time updates on payment status
- [ ] **Split History**: View past bill splitting decisions
- [ ] **Social Features**: Share split details via messaging or email

## 🔧 **Technical Specifications**

### **Database Schema**

```sql
-- Bill splits table
CREATE TABLE bill_splits (
  id BIGINT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  split_method VARCHAR(50) NOT NULL, -- 'equal', 'custom', 'item_based', 'percentage'
  total_amount DECIMAL(10,2) NOT NULL,
  split_amount_total DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  tip_amount DECIMAL(10,2) DEFAULT 0,
  service_charge_amount DECIMAL(10,2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'validated', 'processing', 'completed', 'failed'
  created_by_user_id BIGINT,
  validated_by_user_id BIGINT,
  validated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  FOREIGN KEY (validated_by_user_id) REFERENCES users(id),
  INDEX idx_order_id (order_id),
  INDEX idx_status (status)
);

-- Individual participant splits
CREATE TABLE participant_splits (
  id BIGINT PRIMARY KEY,
  bill_split_id BIGINT NOT NULL,
  participant_id BIGINT NOT NULL, -- References order participants
  participant_name VARCHAR(255),
  participant_email VARCHAR(255),
  participant_phone VARCHAR(20),
  split_amount DECIMAL(10,2) NOT NULL,
  tax_portion DECIMAL(10,2) DEFAULT 0,
  tip_portion DECIMAL(10,2) DEFAULT 0,
  service_charge_portion DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) GENERATED ALWAYS AS (
    split_amount + tax_portion + tip_portion + service_charge_portion
  ) STORED,
  payment_method VARCHAR(50),
  payment_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed', 'refunded'
  payment_reference VARCHAR(255),
  paid_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (bill_split_id) REFERENCES bill_splits(id),
  FOREIGN KEY (participant_id) REFERENCES order_participants(id),
  INDEX idx_bill_split_id (bill_split_id),
  INDEX idx_participant_id (participant_id),
  INDEX idx_payment_status (payment_status)
);

-- Item-based split assignments
CREATE TABLE split_item_assignments (
  id BIGINT PRIMARY KEY,
  participant_split_id BIGINT NOT NULL,
  order_item_id BIGINT NOT NULL,
  quantity DECIMAL(8,2) NOT NULL, -- Allows partial quantities
  item_price DECIMAL(10,2) NOT NULL,
  total_assigned_amount DECIMAL(10,2) GENERATED ALWAYS AS (
    quantity * item_price
  ) STORED,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (participant_split_id) REFERENCES participant_splits(id),
  FOREIGN KEY (order_item_id) REFERENCES order_items(id),
  INDEX idx_participant_split_id (participant_split_id),
  INDEX idx_order_item_id (order_item_id)
);

-- Split validation logs
CREATE TABLE split_validations (
  id BIGINT PRIMARY KEY,
  bill_split_id BIGINT NOT NULL,
  validator_user_id BIGINT NOT NULL,
  validation_type VARCHAR(50) NOT NULL, -- 'amount_check', 'payment_verification', 'final_approval'
  validation_status VARCHAR(20) NOT NULL, -- 'passed', 'failed', 'warning'
  validation_message TEXT,
  validation_data JSON,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (bill_split_id) REFERENCES bill_splits(id),
  FOREIGN KEY (validator_user_id) REFERENCES users(id),
  INDEX idx_bill_split_id (bill_split_id),
  INDEX idx_validation_type (validation_type)
);
```

### **Backend Implementation**

```ruby
class BillSplittingService
  def initialize(order)
    @order = order
    @participants = order.order_participants.active
  end

  def create_split(split_params)
    ActiveRecord::Base.transaction do
      bill_split = create_bill_split_record(split_params)
      participant_splits = create_participant_splits(bill_split, split_params[:participants])

      if split_params[:method] == 'item_based'
        create_item_assignments(participant_splits, split_params[:item_assignments])
      end

      validate_split_amounts(bill_split)

      bill_split
    end
  end

  def validate_split_amounts(bill_split)
    total_split = bill_split.participant_splits.sum(:total_amount)
    order_total = @order.total_amount

    validation_result = {
      split_total: total_split,
      order_total: order_total,
      difference: total_split - order_total,
      status: determine_validation_status(total_split, order_total)
    }

    log_validation(bill_split, validation_result)
    validation_result
  end

  def process_payments(bill_split)
    payment_results = []

    bill_split.participant_splits.each do |participant_split|
      result = process_participant_payment(participant_split)
      payment_results << result
    end

    update_split_status(bill_split, payment_results)
    payment_results
  end

  private

  def create_bill_split_record(params)
    BillSplit.create!(
      order: @order,
      split_method: params[:method],
      total_amount: @order.total_amount,
      split_amount_total: calculate_split_total(params),
      tax_amount: @order.tax_amount,
      tip_amount: params[:tip_amount] || 0,
      service_charge_amount: @order.service_charge_amount || 0,
      created_by_user_id: params[:created_by_user_id]
    )
  end

  def create_participant_splits(bill_split, participants_data)
    participants_data.map do |participant_data|
      ParticipantSplit.create!(
        bill_split: bill_split,
        participant_id: participant_data[:participant_id],
        participant_name: participant_data[:name],
        participant_email: participant_data[:email],
        participant_phone: participant_data[:phone],
        split_amount: participant_data[:amount],
        tax_portion: calculate_tax_portion(participant_data[:amount], bill_split),
        tip_portion: calculate_tip_portion(participant_data[:amount], bill_split),
        service_charge_portion: calculate_service_charge_portion(participant_data[:amount], bill_split),
        payment_method: participant_data[:payment_method]
      )
    end
  end

  def determine_validation_status(split_total, order_total)
    difference = split_total - order_total

    case
    when difference < -0.01 # Underpayment
      'failed'
    when difference > 5.00 # Significant overpayment
      'warning'
    else
      'passed'
    end
  end

  def process_participant_payment(participant_split)
    payment_service = PaymentService.new(
      amount: participant_split.total_amount,
      payment_method: participant_split.payment_method,
      customer_info: {
        name: participant_split.participant_name,
        email: participant_split.participant_email,
        phone: participant_split.participant_phone
      }
    )

    result = payment_service.process_payment

    participant_split.update!(
      payment_status: result[:status],
      payment_reference: result[:reference],
      paid_at: result[:status] == 'completed' ? Time.current : nil
    )

    result
  end
end
```

### **Frontend Implementation**

```html
<!-- Bill Splitting Interface -->
<div class="bill-splitting-container">
  <div class="split-header">
    <h2>Split Bill</h2>
    <div class="order-summary">
      <div class="total-amount">
        <span class="label">Total Amount:</span>
        <span class="amount" id="order-total">$<%= @order.total_amount %></span>
      </div>
      <div class="participant-count">
        <span class="label">Participants:</span>
        <span class="count" id="participant-count"><%= @order.order_participants.count %></span>
      </div>
    </div>
  </div>

  <div class="split-method-selector">
    <h3>How would you like to split the bill?</h3>

    <div class="method-options">
      <label class="method-option">
        <input type="radio" name="split_method" value="equal" checked>
        <div class="option-content">
          <strong>Equal Split</strong>
          <small>Divide equally among all participants</small>
        </div>
      </label>

      <label class="method-option">
        <input type="radio" name="split_method" value="custom">
        <div class="option-content">
          <strong>Custom Amounts</strong>
          <small>Enter specific amounts for each person</small>
        </div>
      </label>

      <label class="method-option">
        <input type="radio" name="split_method" value="item_based">
        <div class="option-content">
          <strong>By Items</strong>
          <small>Assign specific items to each person</small>
        </div>
      </label>

      <label class="method-option">
        <input type="radio" name="split_method" value="percentage">
        <div class="option-content">
          <strong>Percentage Split</strong>
          <small>Split by percentage allocation</small>
        </div>
      </label>
    </div>
  </div>

  <div class="participants-section">
    <h3>Participants</h3>

    <div class="participants-list" id="participants-list">
      <% @order.order_participants.each_with_index do |participant, index| %>
        <div class="participant-row" data-participant-id="<%= participant.id %>">
          <div class="participant-info">
            <div class="participant-name">
              <input type="text" value="<%= participant.name || "Guest #{index + 1}" %>"
                     name="participants[<%= index %>][name]" class="participant-name-input">
            </div>
            <div class="participant-contact">
              <input type="email" placeholder="Email (optional)"
                     name="participants[<%= index %>][email]" class="participant-email-input">
              <input type="tel" placeholder="Phone (optional)"
                     name="participants[<%= index %>][phone]" class="participant-phone-input">
            </div>
          </div>

          <div class="split-amount-section">
            <div class="amount-input-group">
              <label>Amount:</label>
              <input type="number" step="0.01" min="0"
                     name="participants[<%= index %>][amount]"
                     class="split-amount-input"
                     data-participant-index="<%= index %>">
            </div>

            <div class="payment-method-group">
              <label>Payment Method:</label>
              <select name="participants[<%= index %>][payment_method]" class="payment-method-select">
                <option value="card">Credit/Debit Card</option>
                <option value="cash">Cash</option>
                <option value="digital_wallet">Digital Wallet</option>
                <option value="bank_transfer">Bank Transfer</option>
              </select>
            </div>
          </div>

          <div class="participant-actions">
            <button type="button" class="btn-remove-participant" data-participant-index="<%= index %>">
              Remove
            </button>
          </div>
        </div>
      <% end %>
    </div>

    <button type="button" class="btn-add-participant" id="add-participant-btn">
      + Add Participant
    </button>
  </div>

  <div class="split-validation-section">
    <div class="validation-summary" id="validation-summary">
      <div class="validation-row">
        <span class="label">Order Total:</span>
        <span class="amount" id="validation-order-total">$<%= @order.total_amount %></span>
      </div>

      <div class="validation-row">
        <span class="label">Split Total:</span>
        <span class="amount" id="validation-split-total">$0.00</span>
      </div>

      <div class="validation-row difference-row">
        <span class="label">Difference:</span>
        <span class="amount" id="validation-difference">$0.00</span>
      </div>

      <div class="validation-status" id="validation-status">
        <span class="status-indicator"></span>
        <span class="status-message">Enter split amounts to validate</span>
      </div>
    </div>
  </div>

  <div class="split-actions">
    <button type="button" class="btn-secondary" onclick="cancelSplit()">
      Cancel
    </button>
    <button type="button" class="btn-primary" id="process-split-btn" disabled>
      Process Split Payment
    </button>
  </div>
</div>

<!-- Item-Based Split Interface (shown when item_based method selected) -->
<div class="item-assignment-section" id="item-assignment-section" style="display: none;">
  <h3>Assign Items to Participants</h3>

  <div class="order-items-list">
    <% @order.order_items.each do |item| %>
      <div class="order-item-row" data-item-id="<%= item.id %>">
        <div class="item-info">
          <span class="item-name"><%= item.menu_item.name %></span>
          <span class="item-price">$<%= item.price %></span>
          <span class="item-quantity">Qty: <%= item.quantity %></span>
        </div>

        <div class="item-assignments">
          <% @order.order_participants.each_with_index do |participant, index| %>
            <div class="assignment-input">
              <label><%= participant.name || "Guest #{index + 1}" %></label>
              <input type="number" step="0.1" min="0" max="<%= item.quantity %>"
                     name="item_assignments[<%= item.id %>][<%= participant.id %>]"
                     class="item-quantity-input"
                     data-item-id="<%= item.id %>"
                     data-participant-id="<%= participant.id %>">
            </div>
          <% end %>
        </div>

        <div class="item-assignment-status">
          <span class="assigned-quantity">0</span> / <span class="total-quantity"><%= item.quantity %></span>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

## 📊 **Success Metrics**

### **1. Customer Satisfaction**
- [ ] Bill splitting usage rate among group orders
- [ ] Customer feedback on splitting experience
- [ ] Time to complete split payment process
- [ ] Reduction in payment disputes

### **2. Operational Efficiency**
- [ ] Employee time saved on payment processing
- [ ] Reduction in payment errors and discrepancies
- [ ] Successful split payment completion rate
- [ ] Average processing time for split payments

### **3. Business Value**
- [ ] Increase in group order frequency
- [ ] Reduction in unpaid bills
- [ ] Improved cash flow from faster payments
- [ ] Customer retention for group dining

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Splitting (Weeks 1-4)**
- [ ] Database schema and models
- [ ] Basic equal split functionality
- [ ] Employee validation interface
- [ ] Payment processing integration

### **Phase 2: Advanced Methods (Weeks 5-7)**
- [ ] Custom amount splitting
- [ ] Item-based splitting
- [ ] Percentage-based splitting
- [ ] Enhanced validation system

### **Phase 3: User Experience (Weeks 8-10)**
- [ ] Mobile-optimized interface
- [ ] Real-time validation
- [ ] Payment status tracking
- [ ] Receipt generation

## 🎯 **Acceptance Criteria**

### **Must Have**
- [x] Split bill among order participants
- [x] Multiple splitting methods (equal, custom, item-based)
- [x] Employee validation that splits equal/exceed total
- [x] Individual payment processing per participant
- [x] Real-time split amount validation
- [x] Payment status tracking

### **Should Have**
- [x] Tax and tip proportional distribution
- [x] Multiple payment methods per participant
- [x] Overpayment handling and refunds
- [x] Individual receipts for participants
- [x] Mobile-friendly interface

### **Could Have**
- [x] QR code payments for each participant
- [x] Split templates for common scenarios
- [x] Social sharing of split details
- [x] Integration with digital wallets

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

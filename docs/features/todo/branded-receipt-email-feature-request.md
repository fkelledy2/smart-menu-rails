# Branded Receipt Email Feature Request

## 📋 **Feature Overview**

**Feature Name**: Branded Receipt Email and SMS Delivery System
**Priority**: High
**Category**: Customer Experience & Communication
**Estimated Effort**: Medium (5-7 weeks)
**Target Release**: Q1 2026

## 🎯 **User Story**

**As an** employee or customer
**I want to** email or SMS a branded receipt to the customer's contact details
**So that** customers have a digital record of their purchase and the restaurant maintains professional branding

**As a** customer
**I want to** receive a branded digital receipt via email or SMS
**So that** I have a convenient record of my purchase for expense tracking and returns

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Contact Information Collection**
- [ ] **Customer Contact Form**: Simple interface to collect email and/or phone number
- [ ] **Optional vs Required**: Configurable requirement settings per restaurant
- [ ] **Contact Validation**: Real-time validation of email and phone formats
- [ ] **Privacy Compliance**: GDPR/CCPA compliant data collection with consent
- [ ] **Guest Checkout**: Allow receipt delivery without account creation

#### **2. Branded Receipt Generation**
- [ ] **Restaurant Branding**: Custom logo, colors, and styling per restaurant
- [ ] **Professional Layout**: Clean, mobile-friendly receipt design
- [ ] **Complete Order Details**: Items, quantities, prices, taxes, totals
- [ ] **Restaurant Information**: Address, contact details, hours, website
- [ ] **Legal Compliance**: Tax information, receipt numbers, timestamps

#### **3. Multi-Channel Delivery**
- [ ] **Email Delivery**: HTML and plain text receipt emails
- [ ] **SMS Delivery**: Text message with receipt link or PDF attachment
- [ ] **Delivery Confirmation**: Track successful delivery and opens
- [ ] **Retry Logic**: Automatic retry for failed deliveries
- [ ] **Delivery Preferences**: Customer choice of email, SMS, or both

#### **4. Employee and Customer Access**
- [ ] **Employee Interface**: Easy receipt sending from POS or order management
- [ ] **Customer Self-Service**: Customers can request receipts themselves
- [ ] **Bulk Operations**: Send receipts for multiple orders
- [ ] **Historical Access**: Resend receipts for past orders
- [ ] **Permission Controls**: Role-based access to receipt functions

### **Secondary Requirements**

#### **5. Advanced Features**
- [ ] **QR Code Integration**: QR codes for easy receipt access
- [ ] **Digital Wallet**: Add receipts to Apple Wallet or Google Pay
- [ ] **Receipt Analytics**: Track open rates and customer engagement
- [ ] **Promotional Integration**: Include offers or loyalty points in receipts
- [ ] **Multi-language Support**: Receipts in customer's preferred language

#### **6. Integration Capabilities**
- [ ] **Accounting Integration**: Export receipt data to accounting systems
- [ ] **CRM Integration**: Store customer contact data in CRM
- [ ] **Marketing Automation**: Trigger follow-up campaigns from receipts
- [ ] **Analytics Platform**: Track receipt delivery metrics
- [ ] **Third-party Services**: Integration with email/SMS providers

## 🔧 **Technical Specifications**

### **Database Schema**

```sql
-- Customer contact information
CREATE TABLE customer_contacts (
  id BIGINT PRIMARY KEY,
  email VARCHAR(255),
  phone VARCHAR(20),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email_verified BOOLEAN DEFAULT false,
  phone_verified BOOLEAN DEFAULT false,
  marketing_consent BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  INDEX idx_email (email),
  INDEX idx_phone (phone),
  CONSTRAINT chk_contact_method CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

-- Receipt delivery records
CREATE TABLE receipt_deliveries (
  id BIGINT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  customer_contact_id BIGINT,
  delivery_method VARCHAR(20) NOT NULL, -- 'email', 'sms', 'both'
  recipient_email VARCHAR(255),
  recipient_phone VARCHAR(20),
  delivery_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed'
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  opened_at TIMESTAMP,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  created_by_user_id BIGINT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (customer_contact_id) REFERENCES customer_contacts(id),
  FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  INDEX idx_order_id (order_id),
  INDEX idx_delivery_status (delivery_status),
  INDEX idx_sent_at (sent_at)
);

-- Receipt templates for branding
CREATE TABLE receipt_templates (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  template_name VARCHAR(100) NOT NULL,
  template_type VARCHAR(20) NOT NULL, -- 'email', 'sms', 'pdf'
  subject_template VARCHAR(255),
  body_template TEXT NOT NULL,
  styles JSON, -- CSS styles for email templates
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_restaurant_id (restaurant_id),
  INDEX idx_template_type (template_type)
);

-- Receipt delivery analytics
CREATE TABLE receipt_analytics (
  id BIGINT PRIMARY KEY,
  receipt_delivery_id BIGINT NOT NULL,
  event_type VARCHAR(50) NOT NULL, -- 'sent', 'delivered', 'opened', 'clicked'
  event_data JSON,
  user_agent TEXT,
  ip_address INET,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (receipt_delivery_id) REFERENCES receipt_deliveries(id),
  INDEX idx_receipt_delivery_id (receipt_delivery_id),
  INDEX idx_event_type (event_type),
  INDEX idx_created_at (created_at)
);
```

### **Backend Implementation**

```ruby
class ReceiptDeliveryService
  def initialize(order)
    @order = order
    @restaurant = order.restaurant
  end

  def send_receipt(contact_info, delivery_method = 'email', sent_by_user = nil)
    # Validate contact information
    contact = find_or_create_contact(contact_info)
    return { success: false, error: 'Invalid contact information' } unless contact

    # Create delivery record
    delivery = create_delivery_record(contact, delivery_method, sent_by_user)

    # Generate receipt content
    receipt_content = generate_receipt_content(delivery_method)

    # Send via appropriate channel
    case delivery_method
    when 'email'
      send_email_receipt(delivery, receipt_content)
    when 'sms'
      send_sms_receipt(delivery, receipt_content)
    when 'both'
      send_email_receipt(delivery, receipt_content)
      send_sms_receipt(delivery, receipt_content)
    end

    { success: true, delivery: delivery }
  rescue => e
    Rails.logger.error "Receipt delivery failed: #{e.message}"
    delivery&.update(delivery_status: 'failed', error_message: e.message)
    { success: false, error: e.message }
  end

  private

  def find_or_create_contact(contact_info)
    return nil unless valid_contact_info?(contact_info)

    CustomerContact.find_or_create_by(
      email: contact_info[:email]&.downcase,
      phone: normalize_phone(contact_info[:phone])
    ) do |contact|
      contact.first_name = contact_info[:first_name]
      contact.last_name = contact_info[:last_name]
      contact.marketing_consent = contact_info[:marketing_consent] || false
    end
  end

  def generate_receipt_content(delivery_method)
    template = @restaurant.receipt_templates
                          .where(template_type: delivery_method, is_active: true)
                          .first

    template ||= create_default_template(delivery_method)

    ReceiptTemplateRenderer.new(@order, template).render
  end

  def send_email_receipt(delivery, content)
    ReceiptMailer.customer_receipt(
      delivery: delivery,
      content: content
    ).deliver_now

    delivery.update(
      delivery_status: 'sent',
      sent_at: Time.current
    )
  end

  def send_sms_receipt(delivery, content)
    SmsService.send_receipt(
      phone: delivery.recipient_phone,
      message: content[:sms_message],
      receipt_url: content[:receipt_url]
    )

    delivery.update(
      delivery_status: 'sent',
      sent_at: Time.current
    )
  end
end

class ReceiptTemplateRenderer
  def initialize(order, template)
    @order = order
    @template = template
    @restaurant = order.restaurant
  end

  def render
    {
      subject: render_template(@template.subject_template),
      html_body: render_html_template,
      text_body: render_text_template,
      sms_message: render_sms_template,
      receipt_url: generate_receipt_url
    }
  end

  private

  def render_template(template_string)
    ERB.new(template_string).result(binding)
  end

  def render_html_template
    ApplicationController.render(
      template: 'receipts/email_receipt',
      locals: {
        order: @order,
        restaurant: @restaurant,
        template: @template
      }
    )
  end

  def template_variables
    {
      restaurant_name: @restaurant.name,
      restaurant_address: @restaurant.full_address,
      restaurant_phone: @restaurant.phone,
      order_number: @order.number,
      order_date: @order.created_at.strftime('%B %d, %Y at %I:%M %p'),
      order_total: @order.formatted_total,
      order_items: @order.order_items.includes(:menu_item),
      tax_amount: @order.formatted_tax_amount,
      subtotal: @order.formatted_subtotal
    }
  end
end
```

### **Frontend Implementation**

```html
<!-- Receipt Delivery Modal -->
<div id="receipt-delivery-modal" class="modal">
  <div class="modal-content">
    <div class="modal-header">
      <h2>Send Receipt to Customer</h2>
      <button class="close-btn" onclick="closeReceiptModal()">&times;</button>
    </div>

    <div class="modal-body">
      <form id="receipt-delivery-form">
        <div class="customer-info-section">
          <h3>Customer Contact Information</h3>

          <div class="form-row">
            <div class="form-group">
              <label for="customer-first-name">First Name</label>
              <input type="text" id="customer-first-name" name="first_name">
            </div>

            <div class="form-group">
              <label for="customer-last-name">Last Name</label>
              <input type="text" id="customer-last-name" name="last_name">
            </div>
          </div>

          <div class="form-group">
            <label for="customer-email">Email Address</label>
            <input type="email" id="customer-email" name="email"
                   placeholder="customer@example.com">
            <div class="validation-message" id="email-validation"></div>
          </div>

          <div class="form-group">
            <label for="customer-phone">Phone Number (optional)</label>
            <input type="tel" id="customer-phone" name="phone"
                   placeholder="+1 (555) 123-4567">
            <div class="validation-message" id="phone-validation"></div>
          </div>
        </div>

        <div class="delivery-options-section">
          <h3>Delivery Method</h3>

          <div class="delivery-options">
            <label class="delivery-option">
              <input type="radio" name="delivery_method" value="email" checked>
              <span class="option-content">
                <i class="icon-email"></i>
                <strong>Email Receipt</strong>
                <small>Send formatted receipt via email</small>
              </span>
            </label>

            <label class="delivery-option">
              <input type="radio" name="delivery_method" value="sms">
              <span class="option-content">
                <i class="icon-sms"></i>
                <strong>SMS Receipt</strong>
                <small>Send receipt link via text message</small>
              </span>
            </label>

            <label class="delivery-option">
              <input type="radio" name="delivery_method" value="both">
              <span class="option-content">
                <i class="icon-both"></i>
                <strong>Email + SMS</strong>
                <small>Send via both email and text</small>
              </span>
            </label>
          </div>
        </div>

        <div class="consent-section">
          <label class="consent-checkbox">
            <input type="checkbox" name="marketing_consent">
            <span>Customer consents to receive promotional emails (optional)</span>
          </label>
        </div>

        <div class="receipt-preview">
          <h3>Receipt Preview</h3>
          <div class="preview-container">
            <div class="receipt-summary">
              <div class="restaurant-header">
                <img src="<%= @restaurant.logo_url %>" alt="<%= @restaurant.name %>" class="restaurant-logo">
                <h4><%= @restaurant.name %></h4>
              </div>

              <div class="order-details">
                <p><strong>Order #<%= @order.number %></strong></p>
                <p><%= @order.created_at.strftime('%B %d, %Y at %I:%M %p') %></p>
              </div>

              <div class="order-items">
                <% @order.order_items.each do |item| %>
                  <div class="receipt-item">
                    <span class="item-name"><%= item.menu_item.name %></span>
                    <span class="item-quantity">x<%= item.quantity %></span>
                    <span class="item-price"><%= item.formatted_total %></span>
                  </div>
                <% end %>
              </div>

              <div class="receipt-totals">
                <div class="total-line">
                  <span>Subtotal:</span>
                  <span><%= @order.formatted_subtotal %></span>
                </div>
                <div class="total-line">
                  <span>Tax:</span>
                  <span><%= @order.formatted_tax_amount %></span>
                </div>
                <div class="total-line final-total">
                  <span>Total:</span>
                  <span><%= @order.formatted_total %></span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>

    <div class="modal-footer">
      <button type="button" class="btn-secondary" onclick="closeReceiptModal()">
        Cancel
      </button>
      <button type="submit" class="btn-primary" onclick="sendReceipt()">
        Send Receipt
      </button>
    </div>
  </div>
</div>

<!-- Customer Self-Service Receipt Request -->
<div class="customer-receipt-request">
  <h3>Request Digital Receipt</h3>
  <p>Enter your contact information to receive a digital receipt for your order.</p>

  <form id="customer-receipt-form">
    <input type="hidden" name="order_token" value="<%= @order.public_token %>">

    <div class="form-group">
      <label for="receipt-email">Email Address</label>
      <input type="email" id="receipt-email" name="email" required
             placeholder="your@email.com">
    </div>

    <div class="form-group">
      <label for="receipt-phone">Phone Number (optional)</label>
      <input type="tel" id="receipt-phone" name="phone"
             placeholder="+1 (555) 123-4567">
    </div>

    <div class="delivery-preference">
      <label>
        <input type="radio" name="delivery_method" value="email" checked>
        Email Receipt
      </label>
      <label>
        <input type="radio" name="delivery_method" value="sms">
        SMS Receipt
      </label>
    </div>

    <button type="submit" class="btn-primary">
      Send My Receipt
    </button>
  </form>
</div>
```

### **JavaScript Implementation**

```javascript
class ReceiptDeliveryManager {
  constructor() {
    this.form = document.getElementById('receipt-delivery-form');
    this.initEventListeners();
    this.initValidation();
  }

  initEventListeners() {
    // Form submission
    document.getElementById('receipt-delivery-form')?.addEventListener('submit', this.handleSubmit.bind(this));
    document.getElementById('customer-receipt-form')?.addEventListener('submit', this.handleCustomerSubmit.bind(this));

    // Real-time validation
    document.getElementById('customer-email')?.addEventListener('blur', this.validateEmail.bind(this));
    document.getElementById('customer-phone')?.addEventListener('blur', this.validatePhone.bind(this));

    // Delivery method changes
    document.querySelectorAll('[name="delivery_method"]').forEach(radio => {
      radio.addEventListener('change', this.handleDeliveryMethodChange.bind(this));
    });
  }

  async handleSubmit(event) {
    event.preventDefault();

    if (!this.validateForm()) {
      return;
    }

    const formData = new FormData(this.form);
    const data = Object.fromEntries(formData.entries());

    try {
      this.showLoading(true);

      const response = await fetch('/receipt_deliveries', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          order_id: this.getOrderId(),
          contact_info: {
            first_name: data.first_name,
            last_name: data.last_name,
            email: data.email,
            phone: data.phone,
            marketing_consent: data.marketing_consent === 'on'
          },
          delivery_method: data.delivery_method
        })
      });

      const result = await response.json();

      if (result.success) {
        this.showSuccess('Receipt sent successfully!');
        this.closeModal();
        this.trackDelivery(data.delivery_method);
      } else {
        this.showError(result.error || 'Failed to send receipt');
      }
    } catch (error) {
      console.error('Receipt delivery error:', error);
      this.showError('An error occurred while sending the receipt');
    } finally {
      this.showLoading(false);
    }
  }

  validateForm() {
    let isValid = true;

    // Validate email
    const email = document.getElementById('customer-email').value;
    if (!this.isValidEmail(email)) {
      this.showValidationError('email-validation', 'Please enter a valid email address');
      isValid = false;
    } else {
      this.clearValidationError('email-validation');
    }

    // Validate phone if SMS is selected
    const deliveryMethod = document.querySelector('[name="delivery_method"]:checked').value;
    const phone = document.getElementById('customer-phone').value;

    if ((deliveryMethod === 'sms' || deliveryMethod === 'both') && !this.isValidPhone(phone)) {
      this.showValidationError('phone-validation', 'Phone number is required for SMS delivery');
      isValid = false;
    } else {
      this.clearValidationError('phone-validation');
    }

    return isValid;
  }

  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  isValidPhone(phone) {
    const phoneRegex = /^\+?[\d\s\-\(\)]{10,}$/;
    return phoneRegex.test(phone.replace(/\s/g, ''));
  }

  handleDeliveryMethodChange(event) {
    const method = event.target.value;
    const phoneGroup = document.getElementById('customer-phone').closest('.form-group');
    const phoneLabel = phoneGroup.querySelector('label');

    if (method === 'sms' || method === 'both') {
      phoneLabel.textContent = 'Phone Number *';
      phoneGroup.classList.add('required');
    } else {
      phoneLabel.textContent = 'Phone Number (optional)';
      phoneGroup.classList.remove('required');
    }
  }

  showValidationError(elementId, message) {
    const element = document.getElementById(elementId);
    element.textContent = message;
    element.classList.add('error');
  }

  clearValidationError(elementId) {
    const element = document.getElementById(elementId);
    element.textContent = '';
    element.classList.remove('error');
  }

  showLoading(show) {
    const submitBtn = document.querySelector('.modal-footer .btn-primary');
    if (show) {
      submitBtn.disabled = true;
      submitBtn.textContent = 'Sending...';
    } else {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Send Receipt';
    }
  }

  showSuccess(message) {
    // Show success notification
    this.showNotification(message, 'success');
  }

  showError(message) {
    // Show error notification
    this.showNotification(message, 'error');
  }

  showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;

    document.body.appendChild(notification);

    setTimeout(() => {
      notification.remove();
    }, 5000);
  }

  trackDelivery(method) {
    // Analytics tracking
    gtag('event', 'receipt_sent', {
      'event_category': 'Customer Service',
      'event_label': method,
      'value': 1
    });
  }

  getOrderId() {
    return document.querySelector('[data-order-id]')?.dataset.orderId;
  }

  closeModal() {
    document.getElementById('receipt-delivery-modal').style.display = 'none';
  }
}

// Initialize receipt delivery management
document.addEventListener('DOMContentLoaded', () => {
  new ReceiptDeliveryManager();
});
```

## 📊 **Success Metrics**

### **1. Customer Satisfaction**
- [ ] Receipt delivery success rate (target: 98%+)
- [ ] Customer feedback on receipt quality
- [ ] Time to receipt delivery
- [ ] Customer adoption of digital receipts

### **2. Operational Efficiency**
- [ ] Employee time saved on receipt management
- [ ] Reduction in paper receipt costs
- [ ] Automated delivery rate
- [ ] Error rate in contact information

### **3. Business Value**
- [ ] Customer contact database growth
- [ ] Marketing email opt-in rate
- [ ] Receipt open and engagement rates
- [ ] Customer retention improvement

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Functionality (Weeks 1-3)**
- [ ] Database schema and models
- [ ] Basic email receipt delivery
- [ ] Contact information collection
- [ ] Employee interface

### **Phase 2: Enhanced Features (Weeks 4-5)**
- [ ] SMS delivery integration
- [ ] Branded template system
- [ ] Customer self-service
- [ ] Delivery tracking

### **Phase 3: Advanced Features (Weeks 6-7)**
- [ ] Analytics and reporting
- [ ] Template customization
- [ ] Bulk operations
- [ ] Integration capabilities

## 🎯 **Acceptance Criteria**

### **Must Have**
- [x] Collect customer email and phone
- [x] Send branded email receipts
- [x] Employee interface for receipt sending
- [x] Customer self-service receipt request
- [x] Delivery confirmation tracking
- [x] Mobile-responsive design

### **Should Have**
- [x] SMS receipt delivery
- [x] Template customization
- [x] Delivery analytics
- [x] Bulk receipt operations
- [x] Privacy compliance features

### **Could Have**
- [x] QR code integration
- [x] Digital wallet support
- [x] Marketing automation
- [x] Multi-language support

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

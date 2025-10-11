# Table Wait Time Estimation Feature Request

## 📋 **Feature Overview**

**Feature Name**: Intelligent Table Wait Time Estimation System
**Priority**: High
**Category**: Restaurant Operations & Customer Experience
**Estimated Effort**: Large (10-12 weeks)
**Target Release**: Q2 2026

## 🎯 **User Story**

**As a** restaurant manager or employee
**I want to** estimate wait times for tables of given capacity using current and historic data
**So that** I can provide accurate wait time information to waiting customers and improve their dining experience

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Real-Time Table Status Tracking**
- **Table Occupancy Monitoring**: Track current table status (occupied, available, reserved)
- **Seating Capacity Management**: Monitor tables by party size and capacity
- **Service Stage Tracking**: Track dining progress (seated, ordered, served, paying, clearing)
- **Turnover Time Calculation**: Measure actual time from seating to table availability
- **Live Dashboard**: Real-time view of all table statuses and estimated availability

#### **2. Historical Data Analysis**
- **Dining Pattern Analysis**: Analyze historical dining durations by time, day, season
- **Party Size Impact**: Understand how group size affects dining duration
- **Menu Item Influence**: Track how different orders impact table turnover time
- **Seasonal Trends**: Account for holidays, events, and seasonal variations
- **Day-of-Week Patterns**: Different patterns for weekdays vs. weekends

#### **3. Intelligent Wait Time Estimation**
- **Multi-Factor Algorithm**: Consider current occupancy, historical patterns, and queue length
- **Dynamic Adjustments**: Real-time updates based on current service pace
- **Confidence Intervals**: Provide estimated ranges (e.g., 15-25 minutes)
- **Queue Position Tracking**: Show customer's position in waiting queue
- **Capacity-Specific Estimates**: Different estimates for different party sizes

#### **4. Customer Communication Interface**
- **Wait Time Display**: Clear, updated wait time information for staff
- **Queue Management**: Digital waitlist with estimated times
- **Customer Notifications**: SMS/email updates on wait status
- **Self-Service Kiosk**: Allow customers to check wait times independently
- **Mobile Integration**: Wait times accessible via restaurant app or website

### **Secondary Requirements**

#### **5. Advanced Analytics and Reporting**
- **Performance Metrics**: Track accuracy of wait time predictions
- **Operational Insights**: Identify bottlenecks and optimization opportunities
- **Staff Performance**: Analyze service efficiency by shift and staff member
- **Revenue Impact**: Correlate wait times with customer satisfaction and revenue
- **Predictive Modeling**: Forecast busy periods and staffing needs

#### **6. Integration Capabilities**
- **POS Integration**: Connect with point-of-sale systems for order timing
- **Reservation System**: Integrate with existing reservation platforms
- **Staff Scheduling**: Coordinate with staff scheduling systems
- **Customer Database**: Link with customer profiles and preferences
- **Marketing Tools**: Use wait time data for promotional campaigns

## 🔧 **Technical Specifications**

### **Database Schema**

```sql
-- Table configurations and capacity
CREATE TABLE restaurant_tables (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  table_number VARCHAR(20) NOT NULL,
  capacity INTEGER NOT NULL,
  min_party_size INTEGER DEFAULT 1,
  max_party_size INTEGER,
  table_type VARCHAR(50), -- 'standard', 'booth', 'bar', 'outdoor'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_restaurant_id (restaurant_id),
  INDEX idx_capacity (capacity),
  UNIQUE KEY unique_restaurant_table (restaurant_id, table_number)
);

-- Real-time table status tracking
CREATE TABLE table_sessions (
  id BIGINT PRIMARY KEY,
  restaurant_table_id BIGINT NOT NULL,
  party_size INTEGER NOT NULL,
  seated_at TIMESTAMP NOT NULL,
  estimated_duration_minutes INTEGER,
  actual_duration_minutes INTEGER,
  service_stage VARCHAR(50) DEFAULT 'seated', -- 'seated', 'ordered', 'served', 'paying', 'clearing', 'available'
  order_id BIGINT,
  total_amount DECIMAL(10,2),
  staff_member_id BIGINT,
  cleared_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_table_id) REFERENCES restaurant_tables(id),
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (staff_member_id) REFERENCES users(id),
  INDEX idx_restaurant_table_id (restaurant_table_id),
  INDEX idx_seated_at (seated_at),
  INDEX idx_service_stage (service_stage)
);

-- Historical dining patterns
CREATE TABLE dining_patterns (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  table_capacity INTEGER NOT NULL,
  party_size INTEGER NOT NULL,
  day_of_week INTEGER NOT NULL, -- 0=Sunday, 6=Saturday
  hour_of_day INTEGER NOT NULL, -- 0-23
  month_of_year INTEGER NOT NULL, -- 1-12
  average_duration_minutes INTEGER NOT NULL,
  median_duration_minutes INTEGER NOT NULL,
  min_duration_minutes INTEGER NOT NULL,
  max_duration_minutes INTEGER NOT NULL,
  sample_count INTEGER NOT NULL,
  last_calculated_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_restaurant_patterns (restaurant_id, table_capacity, party_size),
  INDEX idx_time_patterns (day_of_week, hour_of_day, month_of_year),
  UNIQUE KEY unique_pattern (restaurant_id, table_capacity, party_size, day_of_week, hour_of_day, month_of_year)
);

-- Wait time estimates and queue
CREATE TABLE wait_time_estimates (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  party_size INTEGER NOT NULL,
  estimated_wait_minutes INTEGER NOT NULL,
  confidence_level DECIMAL(3,2), -- 0.00 to 1.00
  min_wait_minutes INTEGER,
  max_wait_minutes INTEGER,
  queue_position INTEGER,
  factors_considered JSON, -- Store algorithm factors
  created_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_restaurant_party (restaurant_id, party_size),
  INDEX idx_created_at (created_at),
  INDEX idx_expires_at (expires_at)
);

-- Customer wait queue
CREATE TABLE customer_wait_queue (
  id BIGINT PRIMARY KEY,
  restaurant_id BIGINT NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  customer_phone VARCHAR(20),
  customer_email VARCHAR(255),
  party_size INTEGER NOT NULL,
  preferred_table_type VARCHAR(50),
  joined_queue_at TIMESTAMP NOT NULL,
  estimated_wait_minutes INTEGER,
  estimated_seat_time TIMESTAMP,
  queue_position INTEGER,
  status VARCHAR(20) DEFAULT 'waiting', -- 'waiting', 'notified', 'seated', 'cancelled', 'no_show'
  notification_sent_at TIMESTAMP,
  seated_at TIMESTAMP,
  table_session_id BIGINT,
  notes TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  FOREIGN KEY (table_session_id) REFERENCES table_sessions(id),
  INDEX idx_restaurant_queue (restaurant_id, status, queue_position),
  INDEX idx_joined_queue_at (joined_queue_at),
  INDEX idx_party_size (party_size)
);

-- Wait time prediction accuracy tracking
CREATE TABLE wait_time_accuracy (
  id BIGINT PRIMARY KEY,
  wait_time_estimate_id BIGINT NOT NULL,
  customer_wait_queue_id BIGINT NOT NULL,
  predicted_wait_minutes INTEGER NOT NULL,
  actual_wait_minutes INTEGER,
  accuracy_percentage DECIMAL(5,2),
  prediction_factors JSON,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (wait_time_estimate_id) REFERENCES wait_time_estimates(id),
  FOREIGN KEY (customer_wait_queue_id) REFERENCES customer_wait_queue(id),
  INDEX idx_accuracy_tracking (created_at, accuracy_percentage)
);
```

### **Backend Implementation**

```ruby
class WaitTimeEstimationService
  def initialize(restaurant)
    @restaurant = restaurant
    @current_time = Time.current
  end

  def estimate_wait_time(party_size, preferred_table_type = nil)
    # Get current table availability
    available_tables = get_available_tables(party_size, preferred_table_type)

    if available_tables.any?
      return create_estimate(party_size, 0, 1.0, "Tables immediately available")
    end

    # Calculate based on current occupancy and historical patterns
    current_occupancy = analyze_current_occupancy(party_size)
    historical_patterns = get_historical_patterns(party_size)
    queue_impact = calculate_queue_impact(party_size)

    estimated_minutes = calculate_weighted_estimate(
      current_occupancy,
      historical_patterns,
      queue_impact
    )

    confidence = calculate_confidence_level(current_occupancy, historical_patterns)

    create_estimate(party_size, estimated_minutes, confidence, "Based on current and historical data")
  end

  def update_table_status(table_id, status, additional_data = {})
    table_session = TableSession.find_by(restaurant_table_id: table_id, cleared_at: nil)

    case status
    when 'seated'
      create_new_table_session(table_id, additional_data)
    when 'ordered', 'served', 'paying'
      table_session&.update!(service_stage: status)
    when 'clearing'
      table_session&.update!(
        service_stage: status,
        actual_duration_minutes: calculate_duration(table_session.seated_at)
      )
    when 'available'
      complete_table_session(table_session)
      update_dining_patterns(table_session)
    end

    # Recalculate wait times for affected party sizes
    recalculate_wait_times_for_capacity(get_table_capacity(table_id))
  end

  def add_to_wait_queue(customer_info)
    queue_entry = CustomerWaitQueue.create!(
      restaurant: @restaurant,
      customer_name: customer_info[:name],
      customer_phone: customer_info[:phone],
      customer_email: customer_info[:email],
      party_size: customer_info[:party_size],
      preferred_table_type: customer_info[:preferred_table_type],
      joined_queue_at: @current_time,
      queue_position: calculate_queue_position(customer_info[:party_size])
    )

    estimate = estimate_wait_time(customer_info[:party_size])

    queue_entry.update!(
      estimated_wait_minutes: estimate.estimated_wait_minutes,
      estimated_seat_time: @current_time + estimate.estimated_wait_minutes.minutes
    )

    queue_entry
  end

  private

  def analyze_current_occupancy(party_size)
    suitable_tables = @restaurant.restaurant_tables
                                .where('capacity >= ? AND capacity <= ?', party_size, party_size + 2)

    occupied_tables = suitable_tables.joins(:table_sessions)
                                   .where(table_sessions: { cleared_at: nil })

    occupied_sessions = TableSession.joins(:restaurant_table)
                                  .where(restaurant_table: { restaurant: @restaurant })
                                  .where(cleared_at: nil)

    {
      total_suitable_tables: suitable_tables.count,
      occupied_tables: occupied_tables.count,
      average_current_duration: calculate_average_current_duration(occupied_sessions),
      service_stage_distribution: calculate_service_stage_distribution(occupied_sessions)
    }
  end

  def get_historical_patterns(party_size)
    current_hour = @current_time.hour
    current_day = @current_time.wday
    current_month = @current_time.month

    # Get patterns for similar time periods
    patterns = DiningPattern.where(
      restaurant: @restaurant,
      party_size: party_size,
      day_of_week: current_day,
      hour_of_day: (current_hour - 1)..(current_hour + 1),
      month_of_year: current_month
    )

    if patterns.empty?
      # Fallback to broader patterns
      patterns = DiningPattern.where(
        restaurant: @restaurant,
        party_size: party_size,
        day_of_week: current_day
      )
    end

    {
      average_duration: patterns.average(:average_duration_minutes) || 60,
      median_duration: patterns.average(:median_duration_minutes) || 60,
      sample_size: patterns.sum(:sample_count),
      confidence: calculate_pattern_confidence(patterns)
    }
  end

  def calculate_weighted_estimate(current_occupancy, historical_patterns, queue_impact)
    # Weight factors
    current_weight = 0.4
    historical_weight = 0.4
    queue_weight = 0.2

    # Current occupancy estimate
    current_estimate = estimate_from_current_occupancy(current_occupancy)

    # Historical pattern estimate
    historical_estimate = historical_patterns[:average_duration]

    # Queue impact estimate
    queue_estimate = queue_impact[:additional_wait_minutes]

    weighted_estimate = (
      current_estimate * current_weight +
      historical_estimate * historical_weight +
      queue_estimate * queue_weight
    ).round

    # Apply minimum and maximum bounds
    [weighted_estimate, 5].max # Minimum 5 minutes
  end

  def create_estimate(party_size, minutes, confidence, reasoning)
    min_wait = [minutes - 10, 0].max
    max_wait = minutes + 15

    WaitTimeEstimate.create!(
      restaurant: @restaurant,
      party_size: party_size,
      estimated_wait_minutes: minutes,
      confidence_level: confidence,
      min_wait_minutes: min_wait,
      max_wait_minutes: max_wait,
      queue_position: get_queue_position(party_size),
      factors_considered: {
        reasoning: reasoning,
        calculated_at: @current_time,
        algorithm_version: '1.0'
      },
      expires_at: @current_time + 5.minutes
    )
  end
end

class TableStatusTracker
  def self.update_all_table_statuses
    Restaurant.includes(:restaurant_tables, :table_sessions).find_each do |restaurant|
      restaurant.table_sessions.active.each do |session|
        update_session_stage(session)
      end
    end
  end

  def self.update_session_stage(session)
    duration = Time.current - session.seated_at

    # Auto-update service stages based on duration and order status
    case duration.to_i / 60 # Convert to minutes
    when 0..5
      session.update!(service_stage: 'seated') if session.service_stage == 'seated'
    when 5..15
      session.update!(service_stage: 'ordered') if session.order_id.present?
    when 15..45
      session.update!(service_stage: 'served') if order_served?(session)
    when 45..60
      session.update!(service_stage: 'paying') if payment_processing?(session)
    else
      # Flag for manual review if duration exceeds expected
      session.update!(notes: "Long duration - manual review needed")
    end
  end
end
```

### **Frontend Implementation**

```html
<!-- Wait Time Dashboard for Staff -->
<div class="wait-time-dashboard">
  <div class="dashboard-header">
    <h2>Table Wait Time Management</h2>
    <div class="current-time">
      <span id="current-time"><%= Time.current.strftime('%I:%M %p') %></span>
    </div>
  </div>

  <div class="quick-estimates">
    <h3>Current Wait Time Estimates</h3>
    <div class="estimate-cards">
      <% [2, 4, 6, 8].each do |party_size| %>
        <div class="estimate-card" data-party-size="<%= party_size %>">
          <div class="party-size">Party of <%= party_size %></div>
          <div class="wait-time" id="wait-time-<%= party_size %>">
            <span class="minutes">--</span>
            <span class="unit">min</span>
          </div>
          <div class="confidence" id="confidence-<%= party_size %>">
            <span class="confidence-level">--</span>% confidence
          </div>
          <div class="queue-info" id="queue-<%= party_size %>">
            <span class="queue-count">0</span> in queue
          </div>
        </div>
      <% end %>
    </div>
  </div>

  <div class="table-status-grid">
    <h3>Table Status Overview</h3>
    <div class="tables-grid">
      <% @restaurant.restaurant_tables.each do |table| %>
        <div class="table-card" data-table-id="<%= table.id %>">
          <div class="table-header">
            <span class="table-number">Table <%= table.table_number %></span>
            <span class="table-capacity">Seats <%= table.capacity %></span>
          </div>

          <div class="table-status" id="table-status-<%= table.id %>">
            <% if table.current_session %>
              <div class="status-occupied">
                <span class="status-indicator occupied"></span>
                <span class="status-text">Occupied</span>
              </div>

              <div class="session-info">
                <div class="party-info">
                  Party of <%= table.current_session.party_size %>
                </div>
                <div class="duration">
                  <span id="duration-<%= table.id %>">
                    <%= time_ago_in_words(table.current_session.seated_at) %>
                  </span>
                </div>
                <div class="service-stage">
                  <span class="stage-<%= table.current_session.service_stage %>">
                    <%= table.current_session.service_stage.humanize %>
                  </span>
                </div>
              </div>

              <div class="table-actions">
                <select class="stage-selector" onchange="updateTableStage(<%= table.id %>, this.value)">
                  <option value="seated" <%= 'selected' if table.current_session.service_stage == 'seated' %>>Seated</option>
                  <option value="ordered" <%= 'selected' if table.current_session.service_stage == 'ordered' %>>Ordered</option>
                  <option value="served" <%= 'selected' if table.current_session.service_stage == 'served' %>>Served</option>
                  <option value="paying" <%= 'selected' if table.current_session.service_stage == 'paying' %>>Paying</option>
                  <option value="clearing" <%= 'selected' if table.current_session.service_stage == 'clearing' %>>Clearing</option>
                  <option value="available">Mark Available</option>
                </select>
              </div>
            <% else %>
              <div class="status-available">
                <span class="status-indicator available"></span>
                <span class="status-text">Available</span>
              </div>

              <div class="table-actions">
                <button class="btn-seat-party" onclick="seatParty(<%= table.id %>)">
                  Seat Party
                </button>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
  </div>

  <div class="wait-queue-section">
    <h3>Customer Wait Queue</h3>

    <div class="queue-controls">
      <button class="btn-primary" onclick="addToQueue()">
        + Add Customer to Queue
      </button>
      <button class="btn-secondary" onclick="refreshEstimates()">
        Refresh Estimates
      </button>
    </div>

    <div class="queue-list" id="wait-queue-list">
      <% @restaurant.customer_wait_queue.waiting.order(:queue_position).each do |queue_entry| %>
        <div class="queue-entry" data-queue-id="<%= queue_entry.id %>">
          <div class="customer-info">
            <div class="customer-name"><%= queue_entry.customer_name %></div>
            <div class="party-details">
              Party of <%= queue_entry.party_size %>
              <% if queue_entry.preferred_table_type %>
                • <%= queue_entry.preferred_table_type.humanize %>
              <% end %>
            </div>
            <div class="contact-info">
              <% if queue_entry.customer_phone %>
                <span class="phone"><%= queue_entry.customer_phone %></span>
              <% end %>
              <% if queue_entry.customer_email %>
                <span class="email"><%= queue_entry.customer_email %></span>
              <% end %>
            </div>
          </div>

          <div class="wait-info">
            <div class="queue-position">
              #<%= queue_entry.queue_position %> in line
            </div>
            <div class="estimated-wait">
              <span class="wait-time"><%= queue_entry.estimated_wait_minutes %></span> min wait
            </div>
            <div class="estimated-seat-time">
              Est. seat time: <%= queue_entry.estimated_seat_time&.strftime('%I:%M %p') %>
            </div>
          </div>

          <div class="queue-actions">
            <button class="btn-notify" onclick="notifyCustomer(<%= queue_entry.id %>)">
              Notify
            </button>
            <button class="btn-seat" onclick="seatFromQueue(<%= queue_entry.id %>)">
              Seat Now
            </button>
            <button class="btn-remove" onclick="removeFromQueue(<%= queue_entry.id %>)">
              Remove
            </button>
          </div>
        </div>
      <% end %>
    </div>
  </div>
</div>

<!-- Customer-Facing Wait Time Display -->
<div class="customer-wait-display">
  <div class="wait-time-header">
    <h2>Current Wait Times</h2>
    <p>Estimated wait times for available tables</p>
  </div>

  <div class="wait-time-options">
    <% [2, 4, 6, 8].each do |party_size| %>
      <div class="wait-option" data-party-size="<%= party_size %>">
        <div class="party-size-label">
          <i class="icon-people"></i>
          Party of <%= party_size %>
        </div>

        <div class="wait-estimate">
          <span class="wait-minutes" id="customer-wait-<%= party_size %>">--</span>
          <span class="wait-unit">minutes</span>
        </div>

        <div class="wait-range" id="customer-range-<%= party_size %>">
          (-- to -- min)
        </div>

        <button class="btn-join-queue" onclick="joinQueue(<%= party_size %>)">
          Join Wait List
        </button>
      </div>
    <% end %>
  </div>

  <div class="queue-status" id="customer-queue-status" style="display: none;">
    <h3>You're in line!</h3>
    <div class="queue-info">
      <div class="position">Position: <span id="customer-position">#--</span></div>
      <div class="estimated-wait">Estimated wait: <span id="customer-wait">-- minutes</span></div>
      <div class="estimated-time">Estimated seat time: <span id="customer-seat-time">--:--</span></div>
    </div>

    <div class="notification-options">
      <label>
        <input type="checkbox" id="sms-notifications">
        Send SMS updates
      </label>
      <label>
        <input type="checkbox" id="email-notifications">
        Send email updates
      </label>
    </div>
  </div>
</div>
```

## 📊 **Success Metrics**

### **1. Accuracy Metrics**
- Wait time prediction accuracy (target: 80%+ within ±10 minutes)
- Customer satisfaction with wait time communication
- Reduction in customer complaints about wait times
- Improvement in perceived wait time vs. actual wait time

### **2. Operational Efficiency**
- Table turnover rate improvement
- Reduction in no-shows from wait queue
- Staff efficiency in managing customer expectations
- Revenue per available seat hour (RevPASH)

### **3. Customer Experience**
- Customer retention during wait periods
- Wait queue abandonment rate
- Customer feedback scores on wait experience
- Repeat customer rate for busy periods

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Infrastructure (Weeks 1-4)**
- Database schema and models
- Basic table status tracking
- Simple wait time calculation
- Staff dashboard interface

### **Phase 2: Historical Analysis (Weeks 5-7)**
- Historical data collection and analysis
- Pattern recognition algorithms
- Improved estimation accuracy
- Confidence level calculations

### **Phase 3: Advanced Features (Weeks 8-10)**
- Customer queue management
- Notification systems
- Mobile integration
- Analytics and reporting

### **Phase 4: Optimization (Weeks 11-12)**
- Machine learning improvements
- Performance optimization
- Integration with existing systems
- Staff training and documentation

## 🎯 **Acceptance Criteria**

### **Must Have**
- ✅ Real-time table status tracking
- ✅ Historical data analysis for patterns
- ✅ Wait time estimation for different party sizes
- ✅ Staff interface for managing estimates
- ✅ Customer queue management
- ✅ Accuracy tracking and improvement

### **Should Have**
- ✅ Customer notification system
- ✅ Mobile-friendly interfaces
- ✅ Integration with POS systems
- ✅ Advanced analytics and reporting
- ✅ Confidence level indicators

### **Could Have**
- ✅ Machine learning optimization
- ✅ Predictive busy period forecasting
- ✅ Integration with reservation systems
- ✅ Customer preference learning

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

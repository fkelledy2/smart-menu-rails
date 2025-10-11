# Homepage Demo Booking & Video Feature Request

## 📋 **Feature Overview**

**Feature Name**: Homepage Demo Booking and Recorded Demo Viewing
**Priority**: High
**Category**: Marketing & Lead Generation
**Estimated Effort**: Medium (4-6 weeks)
**Target Release**: Q1 2026

## 🎯 **User Story**

**As a** potential customer visiting the mellow.menu website
**I want to** book a live demo of the product and watch a recorded demo
**So that** I can understand the product capabilities and make an informed decision about using mellow.menu for my restaurant

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Live Demo Booking System**
- **Booking Form**: Simple, conversion-optimized form on homepage
- **Calendar Integration**: Real-time availability with Calendly/similar integration
- **Lead Capture**: Collect essential prospect information
- **Confirmation System**: Automated email confirmations and reminders
- **Sales Team Integration**: Automatic lead routing to appropriate sales rep

#### **2. Recorded Demo Video Player**
- **High-Quality Video**: Professional product demonstration video
- **Interactive Player**: Custom video player with engagement tracking
- **Video Analytics**: Track viewing completion rates and engagement
- **Call-to-Action Overlays**: Strategic CTAs during and after video
- **Mobile Optimization**: Responsive video player for all devices

#### **3. Homepage Integration**
- **Hero Section Enhancement**: Prominent demo CTAs in hero area
- **Demo Section**: Dedicated section showcasing both options
- **Social Proof**: Customer testimonials and success stories
- **Progressive Disclosure**: Gradual information revelation to maintain interest

### **Secondary Requirements**

#### **4. Lead Management System**
- **CRM Integration**: Automatic lead creation in sales CRM
- **Lead Scoring**: Qualify leads based on demo engagement
- **Follow-up Automation**: Automated email sequences post-demo
- **Sales Dashboard**: Track demo bookings and conversion metrics

#### **5. Demo Content Management**
- **Video Management**: Easy upload and management of demo videos
- **A/B Testing**: Test different demo videos and booking flows
- **Personalization**: Customize demo content based on visitor behavior
- **Multi-language Support**: Localized demos for different markets

## 🔧 **Technical Specifications**

### **Frontend Implementation**

#### **1. Homepage Hero Section**
```html
<section class="hero-section">
  <div class="hero-content">
    <h1>Transform Your Restaurant with Smart Menu Technology</h1>
    <p>Streamline operations, boost sales, and delight customers with our all-in-one restaurant management platform.</p>

    <div class="demo-cta-buttons">
      <button class="btn-primary" onclick="openDemoBooking()">
        📅 Book Live Demo
      </button>
      <button class="btn-secondary" onclick="openVideoDemo()">
        ▶️ Watch Demo Video
      </button>
    </div>

    <div class="social-proof">
      <p>Trusted by 500+ restaurants worldwide</p>
      <div class="customer-logos">
        <!-- Customer logos -->
      </div>
    </div>
  </div>
</section>
```

#### **2. Demo Booking Modal**
```html
<div id="demo-booking-modal" class="modal">
  <div class="modal-content">
    <h2>Book Your Personalized Demo</h2>
    <p>See how mellow.menu can transform your restaurant operations</p>

    <form id="demo-booking-form">
      <div class="form-group">
        <label>Restaurant Name *</label>
        <input type="text" name="restaurant_name" required>
      </div>

      <div class="form-group">
        <label>Your Name *</label>
        <input type="text" name="contact_name" required>
      </div>

      <div class="form-group">
        <label>Email Address *</label>
        <input type="email" name="email" required>
      </div>

      <div class="form-group">
        <label>Phone Number</label>
        <input type="tel" name="phone">
      </div>

      <div class="form-group">
        <label>Restaurant Type</label>
        <select name="restaurant_type">
          <option value="quick_service">Quick Service</option>
          <option value="casual_dining">Casual Dining</option>
          <option value="fine_dining">Fine Dining</option>
          <option value="cafe">Cafe/Coffee Shop</option>
          <option value="other">Other</option>
        </select>
      </div>

      <div class="form-group">
        <label>Number of Locations</label>
        <select name="location_count">
          <option value="1">1 Location</option>
          <option value="2-5">2-5 Locations</option>
          <option value="6-20">6-20 Locations</option>
          <option value="20+">20+ Locations</option>
        </select>
      </div>

      <div class="form-group">
        <label>What interests you most?</label>
        <textarea name="interests" placeholder="Menu management, online ordering, analytics, etc."></textarea>
      </div>

      <button type="submit" class="btn-primary">
        Schedule My Demo
      </button>
    </form>

    <!-- Calendly integration will appear here after form submission -->
    <div id="calendly-container" style="display: none;"></div>
  </div>
</div>
```

#### **3. Video Demo Player**
```html
<div id="video-demo-modal" class="modal video-modal">
  <div class="modal-content video-content">
    <div class="video-header">
      <h2>See Mellow Menu in Action</h2>
      <p>Watch this 5-minute demo to see how our platform works</p>
    </div>

    <div class="video-player-container">
      <video id="demo-video" controls poster="/assets/demo-thumbnail.jpg">
        <source src="/assets/mellow-menu-demo.mp4" type="video/mp4">
        <source src="/assets/mellow-menu-demo.webm" type="video/webm">
        Your browser does not support the video tag.
      </video>

      <!-- Video overlays for CTAs -->
      <div class="video-overlay" id="video-cta-overlay" style="display: none;">
        <div class="overlay-content">
          <h3>Ready to get started?</h3>
          <button class="btn-primary" onclick="openDemoBooking()">
            Book Your Demo
          </button>
          <button class="btn-secondary" onclick="startFreeTrial()">
            Start Free Trial
          </button>
        </div>
      </div>
    </div>

    <div class="video-chapters">
      <h4>What you'll see in this demo:</h4>
      <ul>
        <li data-time="0">Introduction & Dashboard Overview</li>
        <li data-time="60">Menu Management System</li>
        <li data-time="150">Order Processing & Analytics</li>
        <li data-time="240">Customer Experience</li>
        <li data-time="300">Getting Started</li>
      </ul>
    </div>
  </div>
</div>
```

### **Backend Implementation**

#### **1. Demo Booking Controller**
```ruby
class DemoBookingsController < ApplicationController
  def create
    @demo_booking = DemoBooking.new(demo_booking_params)

    if @demo_booking.save
      # Send to CRM
      CrmService.create_lead(@demo_booking)

      # Send confirmation email
      DemoBookingMailer.confirmation(@demo_booking).deliver_now

      # Generate Calendly link
      calendly_link = CalendlyService.generate_booking_link(@demo_booking)

      render json: {
        success: true,
        calendly_link: calendly_link,
        message: "Demo booking request received successfully!"
      }
    else
      render json: {
        success: false,
        errors: @demo_booking.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def video_analytics
    VideoAnalytics.track_event(
      video_id: params[:video_id],
      event_type: params[:event_type], # play, pause, complete, etc.
      timestamp: params[:timestamp],
      session_id: session.id,
      ip_address: request.remote_ip
    )

    head :ok
  end

  private

  def demo_booking_params
    params.require(:demo_booking).permit(
      :restaurant_name, :contact_name, :email, :phone,
      :restaurant_type, :location_count, :interests
    )
  end
end
```

#### **2. Database Schema**
```sql
-- Demo bookings table
CREATE TABLE demo_bookings (
  id BIGINT PRIMARY KEY,
  restaurant_name VARCHAR(255) NOT NULL,
  contact_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  restaurant_type VARCHAR(50),
  location_count VARCHAR(20),
  interests TEXT,
  calendly_event_id VARCHAR(255),
  demo_completed_at TIMESTAMP,
  conversion_status VARCHAR(50) DEFAULT 'pending',
  sales_rep_id BIGINT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  INDEX idx_email (email),
  INDEX idx_created_at (created_at),
  INDEX idx_conversion_status (conversion_status)
);

-- Video analytics table
CREATE TABLE video_analytics (
  id BIGINT PRIMARY KEY,
  video_id VARCHAR(100) NOT NULL,
  session_id VARCHAR(255),
  event_type VARCHAR(50) NOT NULL,
  timestamp_seconds INTEGER,
  ip_address INET,
  user_agent TEXT,
  referrer VARCHAR(500),
  created_at TIMESTAMP NOT NULL,

  INDEX idx_video_id (video_id),
  INDEX idx_session_id (session_id),
  INDEX idx_created_at (created_at)
);

-- Demo videos table
CREATE TABLE demo_videos (
  id BIGINT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  video_url VARCHAR(500) NOT NULL,
  thumbnail_url VARCHAR(500),
  duration_seconds INTEGER,
  is_active BOOLEAN DEFAULT true,
  view_count INTEGER DEFAULT 0,
  completion_rate DECIMAL(5,2),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### **JavaScript Implementation**

#### **1. Demo Booking Functionality**
```javascript
class DemoBookingManager {
  constructor() {
    this.modal = document.getElementById('demo-booking-modal');
    this.form = document.getElementById('demo-booking-form');
    this.calendlyContainer = document.getElementById('calendly-container');

    this.initEventListeners();
  }

  initEventListeners() {
    this.form.addEventListener('submit', this.handleFormSubmit.bind(this));
  }

  async handleFormSubmit(e) {
    e.preventDefault();

    const formData = new FormData(this.form);
    const data = Object.fromEntries(formData.entries());

    try {
      const response = await fetch('/demo_bookings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ demo_booking: data })
      });

      const result = await response.json();

      if (result.success) {
        this.showCalendlyWidget(result.calendly_link);
        this.trackConversion('demo_booking_submitted');
      } else {
        this.showErrors(result.errors);
      }
    } catch (error) {
      console.error('Demo booking error:', error);
      this.showErrors(['An error occurred. Please try again.']);
    }
  }

  showCalendlyWidget(calendlyLink) {
    this.form.style.display = 'none';
    this.calendlyContainer.style.display = 'block';

    // Initialize Calendly widget
    Calendly.initInlineWidget({
      url: calendlyLink,
      parentElement: this.calendlyContainer
    });
  }

  trackConversion(event) {
    // Google Analytics
    gtag('event', 'conversion', {
      'send_to': 'AW-CONVERSION_ID',
      'event_category': 'Demo',
      'event_label': event
    });

    // Facebook Pixel
    fbq('track', 'Lead');
  }
}
```

#### **2. Video Demo Analytics**
```javascript
class VideoAnalytics {
  constructor(videoElement) {
    this.video = videoElement;
    this.videoId = 'homepage-demo';
    this.sessionId = this.generateSessionId();
    this.milestones = [25, 50, 75, 100]; // Percentage milestones
    this.trackedMilestones = new Set();

    this.initEventListeners();
  }

  initEventListeners() {
    this.video.addEventListener('play', () => this.trackEvent('play'));
    this.video.addEventListener('pause', () => this.trackEvent('pause'));
    this.video.addEventListener('ended', () => this.trackEvent('complete'));
    this.video.addEventListener('timeupdate', () => this.checkMilestones());
  }

  async trackEvent(eventType, timestamp = null) {
    const data = {
      video_id: this.videoId,
      event_type: eventType,
      timestamp: timestamp || Math.floor(this.video.currentTime),
      session_id: this.sessionId
    };

    try {
      await fetch('/demo_bookings/video_analytics', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify(data)
      });
    } catch (error) {
      console.error('Video analytics error:', error);
    }
  }

  checkMilestones() {
    const percentage = (this.video.currentTime / this.video.duration) * 100;

    this.milestones.forEach(milestone => {
      if (percentage >= milestone && !this.trackedMilestones.has(milestone)) {
        this.trackedMilestones.add(milestone);
        this.trackEvent(`milestone_${milestone}`, Math.floor(this.video.currentTime));

        // Show CTA at 75% completion
        if (milestone === 75) {
          this.showVideoOverlay();
        }
      }
    });
  }

  showVideoOverlay() {
    const overlay = document.getElementById('video-cta-overlay');
    overlay.style.display = 'flex';

    // Hide overlay after 10 seconds
    setTimeout(() => {
      overlay.style.display = 'none';
    }, 10000);
  }

  generateSessionId() {
    return 'session_' + Math.random().toString(36).substr(2, 9);
  }
}
```

## 📊 **Success Metrics**

### **1. Conversion Metrics**
- Demo booking conversion rate (target: 3-5%)
- Video completion rate (target: 60%+)
- Demo-to-trial conversion rate (target: 40%+)
- Demo-to-customer conversion rate (target: 15%+)

### **2. Engagement Metrics**
- Average video watch time
- Video engagement score
- Form completion rate
- Time spent on homepage

### **3. Lead Quality Metrics**
- Lead scoring based on engagement
- Sales qualified lead (SQL) rate
- Demo show-up rate (target: 80%+)
- Customer acquisition cost (CAC)

## 🚀 **Implementation Roadmap**

### **Phase 1: Foundation (Weeks 1-2)**
- Database schema and backend models
- Basic demo booking form
- Email confirmation system
- Calendly integration

### **Phase 2: Video Integration (Weeks 3-4)**
- Video player implementation
- Analytics tracking system
- Video overlay CTAs
- Mobile optimization

### **Phase 3: Enhancement (Weeks 5-6)**
- A/B testing framework
- Advanced analytics dashboard
- CRM integration
- Lead scoring system

## 🎯 **Acceptance Criteria**

### **Must Have**
- ✅ Demo booking form with lead capture
- ✅ Calendly integration for scheduling
- ✅ Video demo player with analytics
- ✅ Email confirmation system
- ✅ Mobile-responsive design
- ✅ CRM integration for lead management

### **Should Have**
- ✅ Video engagement tracking
- ✅ A/B testing capabilities
- ✅ Lead scoring system
- ✅ Automated follow-up emails
- ✅ Sales dashboard for tracking

### **Could Have**
- ✅ Personalized demo content
- ✅ Multi-language support
- ✅ Advanced video analytics
- ✅ Social proof integration

---

**Created**: October 11, 2025
**Status**: Draft
**Priority**: High

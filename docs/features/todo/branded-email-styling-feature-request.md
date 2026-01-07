# Branded Email Styling Feature Request

## 📋 **Feature Overview**

**Feature Name**: Mellow Menu Branded Email Templates
**Request Type**: User Experience & Branding Enhancement
**Priority**: Medium-High
**Requested By**: Marketing & Brand Team
**Date**: October 11, 2025

## 🎯 **User Story**

> **During the onboarding flow and registration flow, all emails that are sent by mellow.menu should be branded with the Mellow Menu styling, so that users receive a consistent, professional brand experience that reinforces trust and recognition throughout their journey.**

## 📝 **Detailed Requirements**

### **Primary User Stories**
- [ ] **As a new user**, I want to receive branded emails during registration so I feel confident about the service
- [ ] **As a restaurant owner**, I want onboarding emails to look professional so I trust the platform
- [ ] **As a marketing manager**, I want consistent branding across all touchpoints to build brand recognition
- [ ] **As a user**, I want emails to be visually appealing and easy to read on all devices
- [ ] **As a developer**, I want reusable email templates that maintain brand consistency

### **Email Types Requiring Branding**

#### **Registration & Authentication Emails**
- [ ] **Welcome Email** - Initial registration confirmation
- [ ] **Email Verification** - Confirm email address
- [ ] **Password Reset** - Reset password instructions
- [ ] **Account Activation** - Account setup completion
- [ ] **Login Notifications** - Security alerts for new logins

#### **Onboarding Flow Emails**
- [ ] **Onboarding Welcome** - Getting started guide
- [ ] **Setup Progress** - Restaurant setup milestones
- [ ] **Tutorial Invitations** - Feature walkthrough invitations
- [ ] **Setup Reminders** - Incomplete setup notifications
- [ ] **Onboarding Completion** - Congratulations and next steps

#### **System & Transactional Emails**
- [ ] **Order Confirmations** - Order receipt and details
- [ ] **Payment Notifications** - Billing and payment updates
- [ ] **System Alerts** - Important account notifications
- [ ] **Feature Announcements** - New feature introductions
- [ ] **Support Communications** - Help desk responses

## 🎨 **Brand Design Requirements**

### **Visual Identity Elements**
- [ ] **Logo Placement** - Mellow Menu logo prominently displayed in header
- [ ] **Color Scheme** - Primary brand colors (#FF6B35, #2E8B57, #F7F7F7)
- [ ] **Typography** - Consistent font family (Inter, Roboto, or system fonts)
- [ ] **Spacing & Layout** - Clean, modern layout with proper whitespace
- [ ] **Brand Voice** - Friendly, professional, and approachable tone

### **Design Specifications**
```scss
// Brand Color Palette
$primary-orange: #FF6B35;
$primary-green: #2E8B57;
$light-gray: #F7F7F7;
$dark-gray: #333333;
$white: #FFFFFF;

// Typography
$font-family: 'Inter', 'Roboto', -apple-system, BlinkMacSystemFont, sans-serif;
$font-size-base: 16px;
$line-height: 1.6;

// Layout
$container-width: 600px;
$border-radius: 8px;
$spacing-unit: 16px;
```

## 🏗️ **Technical Implementation**

### **Email Template Structure**
```erb
<!-- app/views/layouts/mailer.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= @email_title || "Mellow Menu" %></title>
    <style>
      <%= render 'shared/email_styles' %>
    </style>
  </head>
  <body>
    <div class="email-container">
      <!-- Header -->
      <div class="email-header">
        <%= image_tag "mellow-menu-logo.png",
            alt: "Mellow Menu",
            class: "logo",
            style: "height: 40px; width: auto;" %>
        <div class="header-tagline">Delightful Dining Experiences</div>
      </div>

      <!-- Main Content -->
      <div class="email-content">
        <%= yield %>
      </div>

      <!-- Footer -->
      <div class="email-footer">
        <div class="footer-links">
          <a href="<%= root_url %>">Visit Website</a> |
          <a href="<%= support_url %>">Get Support</a> |
          <a href="<%= unsubscribe_url %>">Unsubscribe</a>
        </div>
        <div class="footer-text">
          <p>&copy; <%= Date.current.year %> Mellow Menu. All rights reserved.</p>
          <p>Making dining delightful, one meal at a time.</p>
        </div>
        <div class="social-links">
          <a href="#"><%= image_tag "social/twitter.png", alt: "Twitter" %></a>
          <a href="#"><%= image_tag "social/facebook.png", alt: "Facebook" %></a>
          <a href="#"><%= image_tag "social/instagram.png", alt: "Instagram" %></a>
        </div>
      </div>
    </div>
  </body>
</html>
```

### **Email Styles**
```scss
/* app/views/shared/_email_styles.html.erb */
<style type="text/css">
  /* Reset and Base Styles */
  body, table, td, p, a, li, blockquote {
    -webkit-text-size-adjust: 100%;
    -ms-text-size-adjust: 100%;
  }

  body {
    margin: 0;
    padding: 0;
    background-color: #f7f7f7;
    font-family: 'Inter', 'Roboto', -apple-system, BlinkMacSystemFont, sans-serif;
    font-size: 16px;
    line-height: 1.6;
    color: #333333;
  }

  /* Container */
  .email-container {
    max-width: 600px;
    margin: 0 auto;
    background-color: #ffffff;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  /* Header */
  .email-header {
    background: linear-gradient(135deg, #FF6B35 0%, #2E8B57 100%);
    padding: 24px;
    text-align: center;
    color: #ffffff;
  }

  .logo {
    height: 40px;
    width: auto;
    margin-bottom: 8px;
  }

  .header-tagline {
    font-size: 14px;
    opacity: 0.9;
    font-weight: 300;
  }

  /* Content */
  .email-content {
    padding: 32px 24px;
  }

  .email-content h1 {
    color: #FF6B35;
    font-size: 28px;
    font-weight: 600;
    margin: 0 0 16px 0;
    line-height: 1.3;
  }

  .email-content h2 {
    color: #2E8B57;
    font-size: 22px;
    font-weight: 500;
    margin: 24px 0 12px 0;
  }

  .email-content p {
    margin: 0 0 16px 0;
    color: #333333;
  }

  /* Buttons */
  .btn {
    display: inline-block;
    padding: 12px 24px;
    background-color: #FF6B35;
    color: #ffffff !important;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    margin: 16px 0;
    transition: background-color 0.3s ease;
  }

  .btn:hover {
    background-color: #e55a2b;
  }

  .btn-secondary {
    background-color: #2E8B57;
  }

  .btn-secondary:hover {
    background-color: #267a4d;
  }

  /* Cards and Sections */
  .info-card {
    background-color: #f7f7f7;
    border-left: 4px solid #FF6B35;
    padding: 16px;
    margin: 16px 0;
    border-radius: 0 6px 6px 0;
  }

  .success-card {
    background-color: #e8f5e8;
    border-left: 4px solid #2E8B57;
    padding: 16px;
    margin: 16px 0;
    border-radius: 0 6px 6px 0;
  }

  /* Footer */
  .email-footer {
    background-color: #f7f7f7;
    padding: 24px;
    text-align: center;
    border-top: 1px solid #e0e0e0;
  }

  .footer-links {
    margin-bottom: 16px;
  }

  .footer-links a {
    color: #2E8B57;
    text-decoration: none;
    margin: 0 8px;
    font-size: 14px;
  }

  .footer-text {
    font-size: 12px;
    color: #666666;
    margin-bottom: 16px;
  }

  .footer-text p {
    margin: 4px 0;
  }

  .social-links a {
    display: inline-block;
    margin: 0 8px;
  }

  .social-links img {
    width: 24px;
    height: 24px;
  }

  /* Mobile Responsive */
  @media only screen and (max-width: 600px) {
    .email-container {
      margin: 0;
      border-radius: 0;
    }

    .email-content {
      padding: 24px 16px;
    }

    .email-header {
      padding: 20px 16px;
    }

    .email-content h1 {
      font-size: 24px;
    }

    .btn {
      display: block;
      text-align: center;
      margin: 16px 0;
    }
  }
</style>
```

### **Email Template Examples**

#### **Welcome Email Template**
```erb
<!-- app/views/user_mailer/welcome_email.html.erb -->
<% content_for :email_title, "Welcome to Mellow Menu!" %>

<h1>Welcome to Mellow Menu! 🎉</h1>

<p>Hi <%= @user.name %>,</p>

<p>We're thrilled to have you join the Mellow Menu family! You've just taken the first step toward creating delightful dining experiences for your customers.</p>

<div class="success-card">
  <h3>🚀 Your account is ready!</h3>
  <p>Your Mellow Menu account has been successfully created. You can now start setting up your restaurant and creating amazing digital menus.</p>
</div>

<div style="text-align: center; margin: 24px 0;">
  <%= link_to "Get Started Now", onboarding_url, class: "btn" %>
</div>

<h2>What's Next?</h2>

<div class="info-card">
  <h4>📋 Complete Your Setup</h4>
  <p>Add your restaurant details, upload your logo, and customize your menu to get started.</p>
</div>

<div class="info-card">
  <h4>🍽️ Create Your Menu</h4>
  <p>Upload your menu items, set prices, and organize categories for the best customer experience.</p>
</div>

<div class="info-card">
  <h4>📱 Go Live</h4>
  <p>Generate QR codes and start serving customers with your new digital menu system.</p>
</div>

<p>If you have any questions, our support team is here to help. Just reply to this email or visit our help center.</p>

<p>Welcome aboard!</p>

<p><strong>The Mellow Menu Team</strong></p>
```

#### **Email Verification Template**
```erb
<!-- app/views/user_mailer/email_verification.html.erb -->
<% content_for :email_title, "Verify Your Email Address" %>

<h1>Verify Your Email Address</h1>

<p>Hi <%= @user.name %>,</p>

<p>Thanks for signing up with Mellow Menu! To complete your registration and secure your account, please verify your email address by clicking the button below.</p>

<div style="text-align: center; margin: 32px 0;">
  <%= link_to "Verify Email Address", email_verification_url(@user.email_verification_token), class: "btn" %>
</div>

<div class="info-card">
  <h4>🔒 Why verify your email?</h4>
  <ul>
    <li>Secure your account and prevent unauthorized access</li>
    <li>Receive important updates about your restaurant</li>
    <li>Get notified about new orders and customer activity</li>
    <li>Access password reset and account recovery options</li>
  </ul>
</div>

<p>This verification link will expire in 24 hours for security reasons. If you didn't create an account with Mellow Menu, you can safely ignore this email.</p>

<p><strong>Having trouble?</strong> If the button doesn't work, copy and paste this link into your browser:</p>
<p style="word-break: break-all; color: #2E8B57;"><%= email_verification_url(@user.email_verification_token) %></p>

<p>Welcome to the future of dining!</p>

<p><strong>The Mellow Menu Team</strong></p>
```

#### **Onboarding Progress Template**
```erb
<!-- app/views/user_mailer/onboarding_progress.html.erb -->
<% content_for :email_title, "Your Setup Progress - Almost There!" %>

<h1>You're Making Great Progress! 📈</h1>

<p>Hi <%= @user.name %>,</p>

<p>We noticed you've started setting up your Mellow Menu account - that's fantastic! You're <%= @progress_percentage %>% complete with your restaurant setup.</p>

<div class="success-card">
  <h3>✅ What you've completed:</h3>
  <ul>
    <% @completed_steps.each do |step| %>
      <li><%= step %></li>
    <% end %>
  </ul>
</div>

<% if @remaining_steps.any? %>
  <div class="info-card">
    <h3>📋 Next steps to complete:</h3>
    <ul>
      <% @remaining_steps.each do |step| %>
        <li><%= step %></li>
      <% end %>
    </ul>
  </div>
<% end %>

<div style="text-align: center; margin: 24px 0;">
  <%= link_to "Continue Setup", dashboard_url, class: "btn" %>
</div>

<h2>Need Help?</h2>

<p>Our setup process is designed to be simple, but if you need assistance, we're here to help:</p>

<div style="text-align: center; margin: 16px 0;">
  <%= link_to "Watch Setup Tutorial", tutorial_url, class: "btn btn-secondary" %>
  <%= link_to "Contact Support", support_url, class: "btn btn-secondary" %>
</div>

<p>You're so close to launching your digital menu experience. Let's finish this together!</p>

<p><strong>The Mellow Menu Team</strong></p>
```

## 📱 **Mobile Optimization**

### **Responsive Design Principles**
- [ ] **Single Column Layout** - Stack content vertically on mobile
- [ ] **Touch-Friendly Buttons** - Minimum 44px touch targets
- [ ] **Readable Text** - 16px minimum font size
- [ ] **Optimized Images** - Compressed and properly sized
- [ ] **Fast Loading** - Minimal CSS and optimized assets

### **Email Client Compatibility**
```scss
/* Email Client Specific Fixes */

/* Outlook */
<!--[if mso]>
<style type="text/css">
  .email-container {
    width: 600px !important;
  }
  .btn {
    border: none;
    mso-style-priority: 100;
  }
</style>
<![endif]-->

/* Apple Mail Dark Mode */
@media (prefers-color-scheme: dark) {
  .email-container {
    background-color: #1a1a1a !important;
  }
  .email-content {
    color: #ffffff !important;
  }
}

/* Gmail App */
u + .body .email-container {
  width: 100% !important;
}
```

## 🔧 **Implementation Strategy**

### **Mailer Configuration**
```ruby
# config/application.rb
config.action_mailer.default_options = {
  from: 'Mellow Menu <hello@mellow.menu>',
  reply_to: 'support@mellow.menu'
}

# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: 'Mellow Menu <hello@mellow.menu>'
  layout 'mailer'

  protected

  def set_email_metadata(title: nil, category: nil)
    @email_title = title
    @email_category = category
    @unsubscribe_url = unsubscribe_url(token: @user&.unsubscribe_token)
  end
end

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    set_email_metadata(title: "Welcome to Mellow Menu!", category: "onboarding")

    mail(
      to: @user.email,
      subject: "Welcome to Mellow Menu - Let's get started! 🎉"
    )
  end

  def email_verification(user)
    @user = user
    set_email_metadata(title: "Verify Your Email Address", category: "authentication")

    mail(
      to: @user.email,
      subject: "Please verify your email address"
    )
  end
end
```

### **Asset Management**
```ruby
# config/initializers/email_assets.rb
Rails.application.configure do
  # Precompile email assets
  config.assets.precompile += %w[
    mellow-menu-logo.png
    social/twitter.png
    social/facebook.png
    social/instagram.png
  ]
end

# Use asset_url helper for email images
# <%= image_tag asset_url("mellow-menu-logo.png"), alt: "Mellow Menu" %>
```

## 📊 **Email Analytics & Tracking**

### **Email Performance Metrics**
```ruby
# app/models/email_analytics.rb
class EmailAnalytics
  def self.track_email_sent(user, email_type, template)
    EmailEvent.create!(
      user: user,
      event_type: 'sent',
      email_type: email_type,
      template: template,
      timestamp: Time.current
    )
  end

  def self.track_email_opened(user, email_type)
    EmailEvent.create!(
      user: user,
      event_type: 'opened',
      email_type: email_type,
      timestamp: Time.current
    )
  end

  def self.track_link_clicked(user, email_type, link_url)
    EmailEvent.create!(
      user: user,
      event_type: 'clicked',
      email_type: email_type,
      metadata: { link_url: link_url },
      timestamp: Time.current
    )
  end
end
```

## 🧪 **Testing Strategy**

### **Email Template Tests**
```ruby
# test/mailers/user_mailer_test.rb
class UserMailerTest < ActionMailer::TestCase
  test "welcome email has correct branding" do
    user = users(:one)
    email = UserMailer.welcome_email(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Welcome to Mellow Menu - Let's get started! 🎉", email.subject
    assert_equal [user.email], email.to
    assert_equal ["hello@mellow.menu"], email.from

    # Check for branding elements
    assert_match "Mellow Menu", email.body.encoded
    assert_match "mellow-menu-logo.png", email.body.encoded
    assert_match "email-container", email.body.encoded
  end

  test "email verification includes proper styling" do
    user = users(:one)
    email = UserMailer.email_verification(user)

    # Check for branded elements
    assert_match "email-header", email.body.encoded
    assert_match "btn", email.body.encoded
    assert_match "email-footer", email.body.encoded
  end
end

# test/integration/email_rendering_test.rb
class EmailRenderingTest < ActionDispatch::IntegrationTest
  test "emails render correctly across different clients" do
    # Test email rendering with different viewport sizes
    # Test CSS compatibility with major email clients
    # Validate HTML structure and accessibility
  end
end
```

## 🚀 **Implementation Phases**

### **Phase 1: Core Template System (1 week)**
- [ ] Base email layout with branding
- [ ] CSS styling system
- [ ] Logo and asset integration
- [ ] Basic template structure

### **Phase 2: Authentication & Registration Emails (1 week)**
- [ ] Welcome email template
- [ ] Email verification template
- [ ] Password reset template
- [ ] Account activation template

### **Phase 3: Onboarding Email Series (1-2 weeks)**
- [ ] Onboarding welcome sequence
- [ ] Progress tracking emails
- [ ] Setup reminder emails
- [ ] Completion congratulations

### **Phase 4: System & Transactional Emails (1 week)**
- [ ] Order confirmation templates
- [ ] Payment notification templates
- [ ] System alert templates
- [ ] Support communication templates

### **Phase 5: Optimization & Testing (1 week)**
- [ ] Mobile responsiveness testing
- [ ] Email client compatibility
- [ ] Performance optimization
- [ ] A/B testing setup

## 💰 **Business Value**

### **Brand Benefits**
- [ ] **Consistent Experience** - Unified brand presentation across all touchpoints
- [ ] **Professional Image** - High-quality, branded communications build trust
- [ ] **Brand Recognition** - Repeated exposure to brand elements increases recall
- [ ] **Marketing Integration** - Emails become brand marketing opportunities

### **User Experience Benefits**
- [ ] **Trust Building** - Professional emails increase confidence in the service
- [ ] **Clear Communication** - Well-designed emails improve message clarity
- [ ] **Mobile Experience** - Responsive design ensures readability on all devices
- [ ] **Engagement** - Attractive emails increase open and click-through rates

### **Technical Benefits**
- [ ] **Maintainability** - Centralized template system reduces maintenance overhead
- [ ] **Consistency** - Standardized templates prevent design inconsistencies
- [ ] **Scalability** - Reusable components support rapid email development
- [ ] **Analytics** - Branded emails enable better tracking and measurement

## 📋 **Acceptance Criteria**

### **Functional Requirements**
- [ ] All registration emails use Mellow Menu branding
- [ ] All onboarding emails use consistent styling
- [ ] Emails are mobile-responsive and accessible
- [ ] Brand colors and fonts are consistently applied
- [ ] Logo appears correctly in all email clients
- [ ] Footer includes proper branding and links
- [ ] Unsubscribe functionality works correctly

### **Design Requirements**
- [ ] Emails match brand guidelines and color palette
- [ ] Typography is consistent with brand standards
- [ ] Layout is clean, professional, and easy to read
- [ ] Images are optimized and load quickly
- [ ] Buttons and links are clearly styled and functional
- [ ] Social media links are included in footer

### **Technical Requirements**
- [ ] Emails render correctly in major email clients
- [ ] HTML/CSS validates and follows email best practices
- [ ] Images have proper alt text for accessibility
- [ ] Templates are reusable and maintainable
- [ ] Email delivery tracking is implemented
- [ ] Performance is optimized for fast loading

This comprehensive branded email system will ensure that every email communication from Mellow Menu reinforces the brand identity and provides a professional, consistent experience that builds trust and recognition with users throughout their journey.

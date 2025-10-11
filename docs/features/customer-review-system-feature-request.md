# Customer Review System Feature Request

## 📋 **Feature Overview**

**Feature Name**: Customer Review System (Restaurant & Staff Reviews)
**Request Type**: New Feature Enhancement
**Priority**: High
**Requested By**: Customer Experience & Marketing Team
**Date**: October 11, 2025

## 🎯 **User Story**

> **As a customer, I would like to have an option to leave a restaurant review or a staff review at the end of my meal, so that I can share my experience and help other customers make informed decisions while providing valuable feedback to the restaurant.**

## 📝 **Detailed Requirements**

### **Primary User Stories**
1. **As a customer**, I want to rate my overall restaurant experience so others know about service quality
2. **As a customer**, I want to review specific staff members who provided excellent service
3. **As a customer**, I want to leave detailed feedback about food quality, ambiance, and service
4. **As a restaurant owner**, I want to see customer reviews to improve my business
5. **As a staff member**, I want to see my individual reviews to understand my performance
6. **As a potential customer**, I want to read reviews before choosing a restaurant

### **Functional Requirements**

#### **Core Review Functionality**
- **Restaurant Reviews**: Overall restaurant experience rating and feedback
- **Staff Reviews**: Individual staff member performance reviews
- **Rating System**: 5-star rating scale with detailed criteria
- **Written Feedback**: Optional detailed text reviews
- **Review Timing**: Prompt customers at meal completion
- **Anonymous Option**: Allow anonymous reviews for honest feedback

#### **Review Types and Categories**

### **1. Restaurant Reviews** 🏪
- **Overall Experience** (1-5 stars)
- **Food Quality** (1-5 stars)
- **Service Quality** (1-5 stars)
- **Ambiance/Atmosphere** (1-5 stars)
- **Value for Money** (1-5 stars)
- **Cleanliness** (1-5 stars)
- **Written Review** (optional, 500 char limit)
- **Recommendation** (Yes/No - would recommend to others)

### **2. Staff Reviews** 👥
- **Individual Staff Rating** (1-5 stars)
- **Service Categories**:
  - Friendliness & Courtesy
  - Knowledge & Helpfulness
  - Efficiency & Speed
  - Professionalism
- **Specific Feedback** (optional, 300 char limit)
- **Staff Recognition** (highlight exceptional service)

## 🏗️ **Technical Implementation**

### **Database Schema**
```ruby
# Restaurant Reviews Table
class CreateRestaurantReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :restaurant_reviews do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true # null for anonymous
      t.references :ordr, null: true, foreign_key: true # link to specific order

      # Rating categories (1-5 scale)
      t.integer :overall_rating, null: false
      t.integer :food_quality_rating, null: false
      t.integer :service_rating, null: false
      t.integer :ambiance_rating, null: false
      t.integer :value_rating, null: false
      t.integer :cleanliness_rating, null: false

      # Review content
      t.text :review_text, null: true
      t.boolean :would_recommend, default: true
      t.boolean :anonymous, default: false

      # Metadata
      t.string :customer_name, null: true # for anonymous reviews
      t.datetime :visit_date
      t.boolean :verified_visit, default: false
      t.string :status, default: 'pending' # pending, approved, rejected

      t.timestamps
    end

    add_index :restaurant_reviews, [:restaurant_id, :overall_rating]
    add_index :restaurant_reviews, [:restaurant_id, :created_at]
    add_index :restaurant_reviews, :status
  end
end

# Staff Reviews Table
class CreateStaffReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :staff_reviews do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true # null for anonymous
      t.references :ordr, null: true, foreign_key: true
      t.references :restaurant_review, null: true, foreign_key: true

      # Rating categories (1-5 scale)
      t.integer :overall_rating, null: false
      t.integer :friendliness_rating, null: false
      t.integer :knowledge_rating, null: false
      t.integer :efficiency_rating, null: false
      t.integer :professionalism_rating, null: false

      # Review content
      t.text :review_text, null: true
      t.boolean :exceptional_service, default: false
      t.boolean :anonymous, default: false

      # Metadata
      t.string :customer_name, null: true
      t.datetime :visit_date
      t.string :status, default: 'pending'

      t.timestamps
    end

    add_index :staff_reviews, [:employee_id, :overall_rating]
    add_index :staff_reviews, [:restaurant_id, :created_at]
    add_index :staff_reviews, :status
  end
end
```

### **Model Implementation**
```ruby
# app/models/restaurant_review.rb
class RestaurantReview < ApplicationRecord
  belongs_to :restaurant
  belongs_to :user, optional: true
  belongs_to :ordr, optional: true
  has_many :staff_reviews, dependent: :destroy

  enum :status, { pending: 0, approved: 1, rejected: 2, flagged: 3 }

  validates :overall_rating, :food_quality_rating, :service_rating,
            :ambiance_rating, :value_rating, :cleanliness_rating,
            presence: true, inclusion: { in: 1..5 }

  validates :review_text, length: { maximum: 500 }, allow_blank: true
  validates :customer_name, presence: true, if: :anonymous?

  scope :approved, -> { where(status: :approved) }
  scope :recent, -> { order(created_at: :desc) }
  scope :high_rated, -> { where('overall_rating >= ?', 4) }
  scope :low_rated, -> { where('overall_rating <= ?', 2) }

  def average_rating
    [overall_rating, food_quality_rating, service_rating,
     ambiance_rating, value_rating, cleanliness_rating].sum / 6.0
  end

  def reviewer_name
    anonymous? ? (customer_name || 'Anonymous') : user&.name
  end

  def verified?
    ordr.present? && verified_visit?
  end
end

# app/models/staff_review.rb
class StaffReview < ApplicationRecord
  belongs_to :employee
  belongs_to :restaurant
  belongs_to :user, optional: true
  belongs_to :ordr, optional: true
  belongs_to :restaurant_review, optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, flagged: 3 }

  validates :overall_rating, :friendliness_rating, :knowledge_rating,
            :efficiency_rating, :professionalism_rating,
            presence: true, inclusion: { in: 1..5 }

  validates :review_text, length: { maximum: 300 }, allow_blank: true
  validates :customer_name, presence: true, if: :anonymous?

  scope :approved, -> { where(status: :approved) }
  scope :recent, -> { order(created_at: :desc) }
  scope :exceptional, -> { where(exceptional_service: true) }

  def average_rating
    [overall_rating, friendliness_rating, knowledge_rating,
     efficiency_rating, professionalism_rating].sum / 5.0
  end

  def reviewer_name
    anonymous? ? (customer_name || 'Anonymous') : user&.name
  end
end

# Update existing models
class Restaurant < ApplicationRecord
  has_many :restaurant_reviews, dependent: :destroy
  has_many :approved_reviews, -> { approved }, class_name: 'RestaurantReview'

  def average_rating
    approved_reviews.average(:overall_rating) || 0
  end

  def total_reviews_count
    approved_reviews.count
  end

  def rating_distribution
    approved_reviews.group(:overall_rating).count
  end
end

class Employee < ApplicationRecord
  has_many :staff_reviews, dependent: :destroy
  has_many :approved_staff_reviews, -> { approved }, class_name: 'StaffReview'

  def average_rating
    approved_staff_reviews.average(:overall_rating) || 0
  end

  def exceptional_service_count
    approved_staff_reviews.where(exceptional_service: true).count
  end
end
```

### **Controller Implementation**
```ruby
# app/controllers/restaurant_reviews_controller.rb
class RestaurantReviewsController < ApplicationController
  before_action :set_restaurant
  before_action :set_review, only: [:show, :edit, :update, :destroy]

  def index
    @reviews = @restaurant.approved_reviews.recent.includes(:user)
    @average_rating = @restaurant.average_rating
    @total_reviews = @restaurant.total_reviews_count
    @rating_distribution = @restaurant.rating_distribution
  end

  def new
    @review = @restaurant.restaurant_reviews.build
    @order = current_user&.ordrs&.find(params[:order_id]) if params[:order_id]
    @staff_members = @restaurant.employees.active
  end

  def create
    @review = @restaurant.restaurant_reviews.build(review_params)
    @review.user = current_user unless @review.anonymous?
    @review.visit_date = Date.current
    @review.verified_visit = @review.ordr.present?

    if @review.save
      create_staff_reviews if staff_review_params.present?
      send_review_notifications
      redirect_to restaurant_path(@restaurant),
                  notice: 'Thank you for your review! It will be published after moderation.'
    else
      @staff_members = @restaurant.employees.active
      render :new, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:restaurant_review).permit(
      :overall_rating, :food_quality_rating, :service_rating,
      :ambiance_rating, :value_rating, :cleanliness_rating,
      :review_text, :would_recommend, :anonymous, :customer_name, :ordr_id
    )
  end

  def staff_review_params
    params.permit(staff_reviews: {})[:staff_reviews] || {}
  end

  def create_staff_reviews
    staff_review_params.each do |employee_id, staff_data|
      next if staff_data[:overall_rating].blank?

      @restaurant.staff_reviews.create!(
        employee_id: employee_id,
        user: @review.anonymous? ? nil : current_user,
        ordr: @review.ordr,
        restaurant_review: @review,
        overall_rating: staff_data[:overall_rating],
        friendliness_rating: staff_data[:friendliness_rating],
        knowledge_rating: staff_data[:knowledge_rating],
        efficiency_rating: staff_data[:efficiency_rating],
        professionalism_rating: staff_data[:professionalism_rating],
        review_text: staff_data[:review_text],
        exceptional_service: staff_data[:exceptional_service] == '1',
        anonymous: @review.anonymous?,
        customer_name: @review.customer_name,
        visit_date: @review.visit_date
      )
    end
  end

  def send_review_notifications
    ReviewNotificationJob.perform_later(@review)
  end
end
```

## 🎨 **User Interface Design**

### **Review Form Interface**
```erb
<!-- app/views/restaurant_reviews/new.html.erb -->
<div class="review-form-container">
  <div class="review-header">
    <h2>Share Your Experience at <%= @restaurant.name %></h2>
    <p class="text-muted">Your feedback helps other customers and improves our service</p>
  </div>

  <%= form_with model: [@restaurant, @review], local: true, class: "review-form" do |form| %>

    <!-- Restaurant Rating Section -->
    <div class="restaurant-rating-section">
      <h4>Rate Your Experience</h4>

      <div class="rating-categories">
        <div class="rating-item">
          <label>Overall Experience</label>
          <div class="star-rating" data-controller="star-rating" data-field="overall_rating">
            <% (1..5).each do |rating| %>
              <i class="far fa-star" data-rating="<%= rating %>"></i>
            <% end %>
          </div>
          <%= form.hidden_field :overall_rating %>
        </div>

        <div class="rating-item">
          <label>Food Quality</label>
          <div class="star-rating" data-controller="star-rating" data-field="food_quality_rating">
            <% (1..5).each do |rating| %>
              <i class="far fa-star" data-rating="<%= rating %>"></i>
            <% end %>
          </div>
          <%= form.hidden_field :food_quality_rating %>
        </div>

        <!-- Similar for service_rating, ambiance_rating, value_rating, cleanliness_rating -->
      </div>
    </div>

    <!-- Written Review Section -->
    <div class="written-review-section">
      <h4>Tell Us More (Optional)</h4>
      <%= form.text_area :review_text,
          class: "form-control",
          rows: 4,
          placeholder: "Share details about your experience...",
          maxlength: 500 %>
      <small class="text-muted">Maximum 500 characters</small>
    </div>

    <!-- Staff Reviews Section -->
    <div class="staff-reviews-section">
      <h4>Rate Our Staff (Optional)</h4>
      <p class="text-muted">Help us recognize exceptional service</p>

      <% @staff_members.each do |employee| %>
        <div class="staff-review-card">
          <div class="staff-info">
            <img src="<%= employee.image.present? ? employee.image : '/default-avatar.png' %>"
                 alt="<%= employee.name %>" class="staff-avatar">
            <div class="staff-details">
              <h6><%= employee.name %></h6>
              <span class="staff-role"><%= employee.role.humanize %></span>
            </div>
          </div>

          <div class="staff-rating">
            <div class="star-rating" data-controller="star-rating"
                 data-field="staff_reviews[<%= employee.id %>][overall_rating]">
              <% (1..5).each do |rating| %>
                <i class="far fa-star" data-rating="<%= rating %>"></i>
              <% end %>
            </div>

            <div class="exceptional-service">
              <input type="checkbox"
                     name="staff_reviews[<%= employee.id %>][exceptional_service]"
                     value="1"
                     id="exceptional_<%= employee.id %>">
              <label for="exceptional_<%= employee.id %>">
                <i class="fas fa-star text-warning"></i> Exceptional Service
              </label>
            </div>

            <textarea name="staff_reviews[<%= employee.id %>][review_text]"
                      class="form-control mt-2"
                      placeholder="Specific feedback for <%= employee.name %>..."
                      maxlength="300"></textarea>
          </div>
        </div>
      <% end %>
    </div>

    <!-- Review Options -->
    <div class="review-options">
      <div class="form-check">
        <%= form.check_box :would_recommend, class: "form-check-input" %>
        <%= form.label :would_recommend, "I would recommend this restaurant to others",
                       class: "form-check-label" %>
      </div>

      <div class="form-check">
        <%= form.check_box :anonymous, class: "form-check-input" %>
        <%= form.label :anonymous, "Submit anonymously", class: "form-check-label" %>
      </div>

      <div class="anonymous-name" style="display: none;">
        <%= form.text_field :customer_name,
            class: "form-control",
            placeholder: "Your name (for anonymous review)" %>
      </div>
    </div>

    <!-- Hidden fields -->
    <%= form.hidden_field :ordr_id, value: @order&.id %>

    <div class="form-actions">
      <button type="button" class="btn btn-secondary">Cancel</button>
      <%= form.submit "Submit Review", class: "btn btn-primary" %>
    </div>
  <% end %>
</div>
```

### **Review Display Interface**
```erb
<!-- app/views/restaurant_reviews/index.html.erb -->
<div class="reviews-container">
  <div class="reviews-summary">
    <div class="rating-overview">
      <div class="average-rating">
        <span class="rating-number"><%= @average_rating.round(1) %></span>
        <div class="stars">
          <% @average_rating.round.times do %>
            <i class="fas fa-star text-warning"></i>
          <% end %>
          <% (5 - @average_rating.round).times do %>
            <i class="far fa-star text-muted"></i>
          <% end %>
        </div>
        <p><%= @total_reviews %> reviews</p>
      </div>

      <div class="rating-breakdown">
        <% (1..5).reverse_each do |rating| %>
          <div class="rating-bar">
            <span><%= rating %> star</span>
            <div class="progress">
              <div class="progress-bar"
                   style="width: <%= (@rating_distribution[rating] || 0) * 100 / @total_reviews %>%"></div>
            </div>
            <span><%= @rating_distribution[rating] || 0 %></span>
          </div>
        <% end %>
      </div>
    </div>
  </div>

  <div class="reviews-list">
    <% @reviews.each do |review| %>
      <div class="review-card">
        <div class="review-header">
          <div class="reviewer-info">
            <strong><%= review.reviewer_name %></strong>
            <% if review.verified? %>
              <span class="badge bg-success">Verified Visit</span>
            <% end %>
          </div>
          <div class="review-rating">
            <% review.overall_rating.times do %>
              <i class="fas fa-star text-warning"></i>
            <% end %>
            <% (5 - review.overall_rating).times do %>
              <i class="far fa-star text-muted"></i>
            <% end %>
            <small class="text-muted"><%= time_ago_in_words(review.created_at) %> ago</small>
          </div>
        </div>

        <div class="review-content">
          <% if review.review_text.present? %>
            <p><%= simple_format(review.review_text) %></p>
          <% end %>

          <div class="review-categories">
            <span class="category-rating">Food: <%= review.food_quality_rating %>/5</span>
            <span class="category-rating">Service: <%= review.service_rating %>/5</span>
            <span class="category-rating">Ambiance: <%= review.ambiance_rating %>/5</span>
            <span class="category-rating">Value: <%= review.value_rating %>/5</span>
          </div>

          <% if review.would_recommend? %>
            <div class="recommendation">
              <i class="fas fa-thumbs-up text-success"></i>
              Recommends this restaurant
            </div>
          <% end %>
        </div>

        <!-- Staff Reviews for this visit -->
        <% if review.staff_reviews.approved.any? %>
          <div class="staff-reviews-summary">
            <h6>Staff Mentioned:</h6>
            <% review.staff_reviews.approved.each do |staff_review| %>
              <div class="staff-mention">
                <strong><%= staff_review.employee.name %></strong>
                <span class="staff-rating">
                  <%= staff_review.overall_rating %>/5
                  <% if staff_review.exceptional_service? %>
                    <i class="fas fa-star text-warning" title="Exceptional Service"></i>
                  <% end %>
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

## 📱 **JavaScript Implementation**

### **Star Rating Controller**
```javascript
// app/javascript/controllers/star_rating_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { field: String }

  connect() {
    this.stars = this.element.querySelectorAll('.fa-star')
    this.setupEventListeners()
  }

  setupEventListeners() {
    this.stars.forEach((star, index) => {
      star.addEventListener('mouseenter', () => this.highlightStars(index + 1))
      star.addEventListener('mouseleave', () => this.resetHighlight())
      star.addEventListener('click', () => this.selectRating(index + 1))
    })
  }

  highlightStars(rating) {
    this.stars.forEach((star, index) => {
      if (index < rating) {
        star.classList.remove('far')
        star.classList.add('fas', 'text-warning')
      } else {
        star.classList.remove('fas', 'text-warning')
        star.classList.add('far')
      }
    })
  }

  resetHighlight() {
    const currentRating = this.getCurrentRating()
    this.highlightStars(currentRating)
  }

  selectRating(rating) {
    this.setRating(rating)
    this.highlightStars(rating)
  }

  getCurrentRating() {
    const hiddenField = document.querySelector(`input[name*="${this.fieldValue}"]`)
    return parseInt(hiddenField?.value) || 0
  }

  setRating(rating) {
    const hiddenField = document.querySelector(`input[name*="${this.fieldValue}"]`)
    if (hiddenField) {
      hiddenField.value = rating
    }
  }
}
```

## 🔐 **Moderation & Security**

### **Review Moderation System**
```ruby
# app/models/review_moderator.rb
class ReviewModerator
  def self.auto_moderate(review)
    # Auto-approve high ratings from verified customers
    if review.verified? && review.overall_rating >= 4
      review.update(status: :approved)
      return
    end

    # Flag potentially problematic content
    if contains_inappropriate_content?(review.review_text)
      review.update(status: :flagged)
      ReviewModerationJob.perform_later(review)
      return
    end

    # Default to pending for manual review
    review.update(status: :pending)
  end

  private

  def self.contains_inappropriate_content?(text)
    return false if text.blank?

    inappropriate_words = Rails.application.config.inappropriate_words
    text.downcase.split.any? { |word| inappropriate_words.include?(word) }
  end
end
```

## 📊 **Analytics & Reporting**

### **Review Analytics Dashboard**
```ruby
# app/models/analytics/review_analytics.rb
class Analytics::ReviewAnalytics
  def self.restaurant_performance(restaurant)
    {
      average_rating: restaurant.average_rating,
      total_reviews: restaurant.total_reviews_count,
      rating_trend: monthly_rating_trend(restaurant),
      category_breakdown: category_ratings(restaurant),
      staff_performance: staff_ratings(restaurant)
    }
  end

  def self.monthly_rating_trend(restaurant)
    restaurant.approved_reviews
              .group_by_month(:created_at, last: 12)
              .average(:overall_rating)
  end

  def self.category_ratings(restaurant)
    reviews = restaurant.approved_reviews
    {
      food_quality: reviews.average(:food_quality_rating),
      service: reviews.average(:service_rating),
      ambiance: reviews.average(:ambiance_rating),
      value: reviews.average(:value_rating),
      cleanliness: reviews.average(:cleanliness_rating)
    }
  end

  def self.staff_ratings(restaurant)
    restaurant.employees.includes(:approved_staff_reviews)
              .map do |employee|
      {
        name: employee.name,
        average_rating: employee.average_rating,
        total_reviews: employee.approved_staff_reviews.count,
        exceptional_count: employee.exceptional_service_count
      }
    end
  end
end
```

## 🧪 **Testing Strategy**

### **Model Tests**
```ruby
# test/models/restaurant_review_test.rb
class RestaurantReviewTest < ActiveSupport::TestCase
  test "should calculate average rating correctly" do
    review = RestaurantReview.new(
      overall_rating: 5,
      food_quality_rating: 4,
      service_rating: 5,
      ambiance_rating: 4,
      value_rating: 5,
      cleanliness_rating: 4
    )

    assert_equal 4.5, review.average_rating
  end

  test "should require customer name for anonymous reviews" do
    review = RestaurantReview.new(anonymous: true)
    assert_not review.valid?
    assert_includes review.errors[:customer_name], "can't be blank"
  end
end
```

## 🚀 **Implementation Phases**

### **Phase 1: Core Review System (2-3 weeks)**
- Database schema and models
- Basic review creation and display
- Star rating interface
- Restaurant review functionality

### **Phase 2: Staff Reviews (2 weeks)**
- Staff review system
- Employee performance tracking
- Staff recognition features
- Review linking and association

### **Phase 3: Moderation & Analytics (2 weeks)**
- Review moderation system
- Analytics dashboard
- Reporting features
- Performance metrics

### **Phase 4: Enhancement & Integration (1-2 weeks)**
- Mobile optimization
- Email notifications
- Review prompts after meals
- Integration with existing systems

## 💰 **Business Value**

### **Customer Benefits**
- **Informed Decisions** - Read authentic reviews before dining
- **Voice Heard** - Share experiences and feedback
- **Staff Recognition** - Highlight exceptional service
- **Community Building** - Connect with other diners

### **Restaurant Benefits**
- **Customer Insights** - Understand satisfaction levels
- **Staff Performance** - Track individual employee performance
- **Marketing Tool** - Showcase positive reviews
- **Improvement Areas** - Identify areas needing attention

### **Revenue Impact**
- **Trust Building** - Reviews increase customer confidence
- **Staff Motivation** - Recognition improves service quality
- **Reputation Management** - Address issues proactively
- **Competitive Advantage** - Stand out with excellent reviews

## 📋 **Acceptance Criteria**

### **Functional Requirements**
- [ ] Customers can rate restaurants on 6 categories (1-5 stars)
- [ ] Customers can leave written reviews (optional)
- [ ] Customers can rate individual staff members
- [ ] Reviews can be submitted anonymously
- [ ] Reviews are moderated before publication
- [ ] Restaurant owners can view analytics
- [ ] Staff can see their individual reviews

### **User Experience Requirements**
- [ ] Intuitive star rating interface
- [ ] Mobile-responsive design
- [ ] Fast review submission (<3 seconds)
- [ ] Clear review display and organization
- [ ] Easy staff selection and rating
- [ ] Helpful review prompts and guidance

This comprehensive review system will enhance customer engagement, provide valuable feedback to restaurants, and help build trust in the dining community through authentic customer experiences.

require 'test_helper'

class ContactFormEmailTest < ActionDispatch::IntegrationTest
  def setup
    # Clear any existing emails
    ActionMailer::Base.deliveries.clear
    
    @valid_contact_params = {
      contact: {
        email: 'customer@example.com',
        message: 'I would like to know more about your smart menu system for my restaurant.'
      }
    }
    
    @invalid_contact_params = {
      contact: {
        email: '',
        message: ''
      }
    }
  end

  test 'contact form submission sends both receipt and notification emails' do
    # Verify no emails before submission
    assert_equal 0, ActionMailer::Base.deliveries.count
    
    # Submit valid contact form
    post contacts_path, params: @valid_contact_params
    
    # Verify redirect (successful submission)
    assert_redirected_to root_url
    follow_redirect!
    assert_match /thanks/i, flash[:notice]
    
    # Verify exactly 2 emails were sent
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    emails = ActionMailer::Base.deliveries
    
    # Find receipt and notification emails
    receipt_email = emails.find { |email| email.to.include?('customer@example.com') }
    notification_email = emails.find { |email| email.to.include?('admin@mellow.menu') }
    
    # Verify receipt email exists and has correct properties
    assert_not_nil receipt_email, 'Receipt email should be sent to customer'
    assert_equal ['customer@example.com'], receipt_email.to
    assert_equal ['admin@mellow.menu'], receipt_email.from
    assert_match /thanks/i, receipt_email.subject
    
    # Verify notification email exists and has correct properties
    assert_not_nil notification_email, 'Notification email should be sent to admin'
    assert_includes notification_email.to, 'admin@mellow.menu'
    assert_equal ['admin@mellow.menu'], notification_email.from
    assert_match /contact.*form/i, notification_email.subject
    assert_match 'customer@example.com', notification_email.body.encoded
    assert_match 'smart menu system', notification_email.body.encoded
  end

  test 'invalid contact form submission does not send emails' do
    # Verify no emails before submission
    assert_equal 0, ActionMailer::Base.deliveries.count
    
    # Submit invalid contact form
    post contacts_path, params: @invalid_contact_params
    
    # Verify form is re-rendered (not redirected)
    assert_response :success
    assert_template :new
    
    # Verify no emails were sent
    assert_equal 0, ActionMailer::Base.deliveries.count
  end

  test 'contact form from home page sends emails correctly' do
    # First visit the home page
    get root_path
    assert_response :success
    
    # Clear deliveries after any potential tracking emails
    ActionMailer::Base.deliveries.clear
    
    # Submit contact form from home page context
    post contacts_path, params: @valid_contact_params
    
    # Verify emails were sent
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    emails = ActionMailer::Base.deliveries
    customer_email = emails.find { |email| email.to.include?('customer@example.com') }
    admin_email = emails.find { |email| email.to.include?('admin@mellow.menu') }
    
    assert_not_nil customer_email
    assert_not_nil admin_email
  end

  test 'contact form handles special characters in email content' do
    special_params = {
      contact: {
        email: 'test@café-restaurant.com',
        message: 'Hello! We have a café & restaurant with special characters: àáâãäå'
      }
    }
    
    ActionMailer::Base.deliveries.clear
    
    post contacts_path, params: special_params
    
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    # Verify emails handle special characters correctly
    emails = ActionMailer::Base.deliveries
    notification_email = emails.find { |email| email.to.include?('admin@mellow.menu') }
    
    assert_not_nil notification_email
    assert_match 'test@café-restaurant.com', notification_email.body.encoded
    assert_match 'àáâãäå', notification_email.body.encoded
  end

  test 'contact form handles long messages correctly' do
    long_message = 'A' * 1000 + ' This is a very long message about our restaurant needs.'
    
    long_params = {
      contact: {
        email: 'restaurant@example.com',
        message: long_message
      }
    }
    
    ActionMailer::Base.deliveries.clear
    
    post contacts_path, params: long_params
    
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    # Verify notification email includes the full long message
    emails = ActionMailer::Base.deliveries
    notification_email = emails.find { |email| email.to.include?('admin@mellow.menu') }
    
    assert_not_nil notification_email
    assert_match long_message, notification_email.body.encoded
  end

  test 'contact form works for both anonymous and authenticated users' do
    # Test as anonymous user
    ActionMailer::Base.deliveries.clear
    
    post contacts_path, params: @valid_contact_params
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    # Test as authenticated user
    ActionMailer::Base.deliveries.clear
    sign_in users(:one)
    
    authenticated_params = {
      contact: {
        email: 'authenticated@example.com',
        message: 'Message from authenticated user'
      }
    }
    
    post contacts_path, params: authenticated_params
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    # Verify emails contain correct information
    emails = ActionMailer::Base.deliveries
    notification_email = emails.find { |email| email.to.include?('admin@mellow.menu') }
    
    assert_match 'authenticated@example.com', notification_email.body.encoded
    assert_match 'authenticated user', notification_email.body.encoded
  end

  test 'email delivery failures are handled gracefully' do
    # Mock email delivery to raise an exception
    ContactMailer.stub :receipt, -> (contact) { raise StandardError.new('Email service unavailable') } do
      # This should not crash the application
      assert_raises(StandardError) do
        post contacts_path, params: @valid_contact_params
      end
    end
  end

  test 'contact form submission includes proper email headers' do
    ActionMailer::Base.deliveries.clear
    
    post contacts_path, params: @valid_contact_params
    
    emails = ActionMailer::Base.deliveries
    
    emails.each do |email|
      # Verify all emails have required headers
      assert_not_nil email.subject
      assert_not_nil email.to
      assert_not_nil email.from
      assert_not_nil email.body
      assert_not_nil email.date
      
      # Verify proper email format
      assert email.to.all? { |addr| addr.include?('@') }
      assert email.from.all? { |addr| addr.include?('@') }
    end
  end

  test 'contact form tracks analytics and sends emails' do
    # Mock analytics service to verify it's called
    analytics_calls = []
    
    AnalyticsService.stub :track_anonymous_event, ->(id, event, data) { analytics_calls << [id, event, data] } do
      ActionMailer::Base.deliveries.clear
      
      post contacts_path, params: @valid_contact_params
      
      # Verify emails were sent
      assert_equal 2, ActionMailer::Base.deliveries.count
      
      # Verify analytics was tracked
      assert_equal 1, analytics_calls.count
      assert_equal 'contact_form_submitted', analytics_calls.first[1]
    end
  end

  private

  def assert_email_delivered_to(email_address)
    delivered_emails = ActionMailer::Base.deliveries
    matching_email = delivered_emails.find { |email| email.to.include?(email_address) }
    assert_not_nil matching_email, "No email was delivered to #{email_address}"
    matching_email
  end

  def assert_email_contains(email, content)
    assert_match content, email.body.encoded, "Email body should contain '#{content}'"
  end
end

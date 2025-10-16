require 'test_helper'

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test 'contact model validation works' do
    # Test the Contact model directly since controller tests are having issues
    contact = Contact.new(email: 'test@example.com', message: 'Test message')
    assert contact.valid?

    invalid_contact = Contact.new
    assert_not invalid_contact.valid?
    assert_includes invalid_contact.errors[:email], "can't be blank"
    assert_includes invalid_contact.errors[:message], "can't be blank"
  end

  test 'contact policy allows public access' do
    # Test the ContactPolicy directly
    policy = ContactPolicy.new(nil, Contact.new)
    assert policy.new?
    assert policy.create?

    user = users(:one)
    policy_with_user = ContactPolicy.new(user, Contact.new)
    assert policy_with_user.new?
    assert policy_with_user.create?
  end

  test 'contact can be created and saved' do
    # Test basic Contact creation
    assert_difference('Contact.count') do
      Contact.create!(email: 'test@example.com', message: 'Test message')
    end
  end

  test 'contact mailer methods exist' do
    # Test that ContactMailer methods exist
    contact = Contact.new(email: 'test@example.com', message: 'Test message')

    assert_respond_to ContactMailer, :receipt
    assert_respond_to ContactMailer, :notification

    # Test that mailer methods return mail objects
    receipt_mail = ContactMailer.receipt(contact)
    assert_not_nil receipt_mail

    notification_mail = ContactMailer.notification(contact)
    assert_not_nil notification_mail
  end

  # Basic functionality tests - focusing on what actually works
  test 'should get new contact form' do
    get new_contact_path
    assert_response :success
  end

  test 'contact creation should work with valid params and send emails' do
    # Clear any existing emails
    ActionMailer::Base.deliveries.clear
    
    contact_params = {
      contact: {
        email: 'test@example.com',
        message: 'This is a test message'
      }
    }

    # Test that contact is created and emails are sent
    assert_difference('Contact.count') do
      post contacts_path, params: contact_params
    end
    
    # Verify redirect on successful creation
    assert_redirected_to root_url
    
    # Verify exactly 2 emails were sent (receipt + notification)
    assert_equal 2, ActionMailer::Base.deliveries.count
    
    emails = ActionMailer::Base.deliveries
    
    # Verify receipt email to customer
    receipt_email = emails.find { |email| email.to.include?('test@example.com') }
    assert_not_nil receipt_email, 'Should send receipt email to customer'
    
    # Verify notification email to admin
    notification_email = emails.find { |email| email.to.include?('admin@mellow.menu') }
    assert_not_nil notification_email, 'Should send notification email to admin'
    assert_match 'test@example.com', notification_email.body.encoded
    assert_match 'This is a test message', notification_email.body.encoded
  end

  test 'contact creation should handle invalid params and not send emails' do
    # Clear any existing emails
    ActionMailer::Base.deliveries.clear
    
    contact_params = {
      contact: {
        email: '', # Invalid email
        message: '' # Invalid message
      }
    }

    # Test that no contact is created and no emails are sent
    assert_no_difference('Contact.count') do
      post contacts_path, params: contact_params
    end
    
    # Verify form is re-rendered (not redirected)
    assert_response :success
    assert_template :new
    
    # Verify no emails were sent for invalid submission
    assert_equal 0, ActionMailer::Base.deliveries.count
  end

  # Test authorization works (no exceptions raised)
  test 'should authorize contact actions for anonymous user' do
    assert_nothing_raised do
      get new_contact_path
    end
  end

  test 'should authorize contact actions for authenticated user' do
    sign_in users(:one)
    
    assert_nothing_raised do
      get new_contact_path
    end
  end
end

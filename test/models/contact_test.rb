require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  test 'should be valid with email and message' do
    contact = Contact.new(email: 'test@example.com', message: 'Test message')
    assert contact.valid?
  end

  test 'should require email' do
    contact = Contact.new(message: 'Test message')
    assert_not contact.valid?
    assert_includes contact.errors[:email], "can't be blank"
  end

  test 'should require message' do
    contact = Contact.new(email: 'test@example.com')
    assert_not contact.valid?
    assert_includes contact.errors[:message], "can't be blank"
  end

  test 'should save valid contact' do
    contact = Contact.new(email: 'test@example.com', message: 'Test message')
    assert contact.save
    assert_not_nil contact.id
  end

  test 'should not save invalid contact' do
    contact = Contact.new
    assert_not contact.save
    assert contact.errors.any?
  end

  test 'should handle long messages' do
    long_message = 'A' * 1000
    contact = Contact.new(email: 'test@example.com', message: long_message)
    assert contact.valid?
  end

  test 'should handle various email formats' do
    valid_emails = [
      'test@example.com',
      'user.name@domain.co.uk',
      'first+last@subdomain.example.org',
    ]

    valid_emails.each do |email|
      contact = Contact.new(email: email, message: 'Test message')
      assert contact.valid?, "#{email} should be valid"
    end
  end

  test 'should store email and message correctly' do
    email = 'test@example.com'
    message = 'This is a test message'

    contact = Contact.create!(email: email, message: message)

    assert_equal email, contact.email
    assert_equal message, contact.message
  end

  test 'should have timestamps' do
    contact = Contact.create!(email: 'test@example.com', message: 'Test message')

    assert_not_nil contact.created_at
    assert_not_nil contact.updated_at
  end
end

require 'test_helper'

class ContactMailerTest < ActionMailer::TestCase
  def setup
    @contact = Contact.new(
      email: 'test@example.com',
      message: 'This is a test message from the contact form.',
    )
  end

  test 'receipt email should be sent to contact' do
    mail = ContactMailer.receipt(@contact)

    assert_equal [@contact.email], mail.to
    assert_equal ['admin@mellow.menu'], mail.from
    assert_match 'Thanks for connecting', mail.subject
    assert_match 'Welcome to Mellow Menu', mail.body.encoded
  end

  test 'notification email should be sent to admin' do
    mail = ContactMailer.notification(@contact)

    assert_includes mail.to, 'admin@mellow.menu'
    assert_equal ['admin@mellow.menu'], mail.from
    assert_match 'New Contact Form Submission', mail.subject
    assert_match @contact.email, mail.body.encoded
    assert_match @contact.message, mail.body.encoded
  end

  test 'receipt email should have proper headers' do
    mail = ContactMailer.receipt(@contact)

    assert_not_nil mail.subject
    assert_not_nil mail.to
    assert_not_nil mail.from
    assert_not_nil mail.body
  end

  test 'notification email should have proper headers' do
    mail = ContactMailer.notification(@contact)

    assert_not_nil mail.subject
    assert_not_nil mail.to
    assert_not_nil mail.from
    assert_not_nil mail.body
  end

  test 'should handle contact with long message' do
    long_message = 'A' * 1000
    contact = Contact.new(email: 'test@example.com', message: long_message)

    # Receipt email doesn't include the message, just a thank you
    mail = ContactMailer.receipt(contact)
    assert_match 'Welcome to Mellow Menu', mail.body.encoded

    # Notification email includes the full message
    mail = ContactMailer.notification(contact)
    assert_match long_message, mail.body.encoded
  end

  test 'should handle contact with special characters' do
    special_message = 'Hello! This message contains special characters: àáâãäå æç èéêë'
    contact = Contact.new(email: 'test@example.com', message: special_message)

    mail = ContactMailer.receipt(contact)
    assert_not_nil mail.body

    mail = ContactMailer.notification(contact)
    assert_not_nil mail.body
  end

  test 'should handle different email formats' do
    emails = [
      'simple@example.com',
      'user.name@domain.co.uk',
      'first+last@subdomain.example.org',
    ]

    emails.each do |email|
      contact = Contact.new(email: email, message: 'Test message')

      mail = ContactMailer.receipt(contact)
      assert_equal [email], mail.to

      mail = ContactMailer.notification(contact)
      assert_match email, mail.body.encoded
    end
  end

  test 'emails should be deliverable' do
    mail = ContactMailer.receipt(@contact)
    assert_nothing_raised do
      mail.deliver_now
    end

    mail = ContactMailer.notification(@contact)
    assert_nothing_raised do
      mail.deliver_now
    end
  end

  test 'should handle HTML content in message' do
    html_message = "This message contains <b>HTML</b> and <script>alert('test')</script>"
    contact = Contact.new(email: 'test@example.com', message: html_message)

    mail = ContactMailer.receipt(contact)
    assert_not_nil mail.body

    mail = ContactMailer.notification(contact)
    assert_not_nil mail.body
  end
end

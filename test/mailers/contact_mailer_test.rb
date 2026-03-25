require 'test_helper'

class ContactMailerTest < ActionMailer::TestCase
  def setup
    @contact = Contact.new(
      email: 'test@example.com',
      message: 'This is a test message from the contact form.',
    )
  end

  # ─── receipt ───────────────────────────────────────────────────────────────

  test 'receipt email is sent to the contact' do
    mail = ContactMailer.receipt(@contact)
    assert_equal [@contact.email], mail.to
  end

  test 'receipt email is sent from the Mellow Menu address' do
    mail = ContactMailer.receipt(@contact)
    assert_equal ['hello@mellow.menu'], mail.from
  end

  test 'receipt email has correct subject' do
    mail = ContactMailer.receipt(@contact)
    assert_match 'Thanks for connecting', mail.subject
  end

  test 'receipt email HTML body contains thanks heading' do
    mail = ContactMailer.receipt(@contact)
    assert_match(/Thanks for getting in touch/i, mail.html_part.body.decoded)
  end

  test 'receipt email HTML body contains CTA link to mellow.menu' do
    mail = ContactMailer.receipt(@contact)
    assert_match(/mellow\.menu/i, mail.html_part.body.decoded)
  end

  test 'receipt email has a plain-text part' do
    mail = ContactMailer.receipt(@contact)
    assert_not_nil mail.text_part
    assert_match(/Thanks for getting in touch/i, mail.text_part.body.decoded)
  end

  test 'receipt email HTML layout footer contains privacy policy link' do
    mail = ContactMailer.receipt(@contact)
    assert_match(/Privacy Policy/i, mail.html_part.body.decoded)
  end

  # ─── notification ──────────────────────────────────────────────────────────

  test 'notification email is sent to the Mellow Menu admin address' do
    mail = ContactMailer.notification(@contact)
    assert_includes mail.to, 'hello@mellow.menu'
  end

  test 'notification email is sent from the Mellow Menu address' do
    mail = ContactMailer.notification(@contact)
    assert_equal ['hello@mellow.menu'], mail.from
  end

  test 'notification email has correct subject' do
    mail = ContactMailer.notification(@contact)
    assert_match 'New Contact Form Submission', mail.subject
  end

  test 'notification email HTML body contains sender email' do
    mail = ContactMailer.notification(@contact)
    assert_match @contact.email, mail.html_part.body.decoded
  end

  test 'notification email HTML body contains the message' do
    mail = ContactMailer.notification(@contact)
    assert_match @contact.message, mail.html_part.body.decoded
  end

  test 'notification email has a plain-text part with message' do
    mail = ContactMailer.notification(@contact)
    assert_not_nil mail.text_part
    assert_match @contact.message, mail.text_part.body.decoded
  end

  # ─── shared headers ────────────────────────────────────────────────────────

  test 'all contact emails have required headers' do
    [ContactMailer.receipt(@contact), ContactMailer.notification(@contact)].each do |mail|
      assert_not_nil mail.subject
      assert_not_nil mail.to
      assert_not_nil mail.from
      assert_not_nil mail.body
    end
  end

  test 'all contact emails are deliverable without error' do
    assert_nothing_raised { ContactMailer.receipt(@contact).deliver_now }
    assert_nothing_raised { ContactMailer.notification(@contact).deliver_now }
  end

  test 'handles contact with long message' do
    long_message = 'A' * 1000
    contact = Contact.new(email: 'test@example.com', message: long_message)

    # Receipt does not include the message, just a thank-you
    mail = ContactMailer.receipt(contact)
    assert_match(/Thanks for getting in touch/i, mail.html_part.body.decoded)

    # Notification includes the full message
    mail = ContactMailer.notification(contact)
    assert_match long_message, mail.html_part.body.decoded
  end

  test 'handles contact with special characters in message' do
    special_message = 'Hello! This message contains special characters: àáâãäå æç èéêë'
    contact = Contact.new(email: 'test@example.com', message: special_message)

    mail = ContactMailer.receipt(contact)
    assert_not_nil mail.body

    mail = ContactMailer.notification(contact)
    assert_not_nil mail.body
  end

  test 'handles different email address formats' do
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
      assert_match email, mail.html_part.body.decoded
    end
  end
end

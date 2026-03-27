# frozen_string_literal: true

require 'test_helper'

class DemoBookingMailerTest < ActionMailer::TestCase
  def setup
    @booking = DemoBooking.new(
      restaurant_name: 'The Harbour Kitchen',
      contact_name: 'Jane Smith',
      email: 'jane@therestaurant.com',
      phone: '+353 1 234 5678',
      restaurant_type: 'casual_dining',
      location_count: '2-5',
      interests: 'QR ordering and auto-pay',
      conversion_status: 'pending',
    )
  end

  def mail
    DemoBookingMailer.confirmation(@booking)
  end

  # ---------------------------------------------------------------------------
  # Envelope
  # ---------------------------------------------------------------------------

  test 'is addressed to the prospect email' do
    assert_equal ['jane@therestaurant.com'], mail.to
  end

  test 'is cc-d to the demos inbox' do
    assert_equal ['demos@mellow.menu'], mail.cc
  end

  test 'is sent from the Mellow Menu address' do
    assert_equal ['hello@mellow.menu'], mail.from
  end

  test 'subject includes the contact name' do
    assert_match 'Jane Smith', mail.subject
  end

  test 'subject includes mellow.menu branding' do
    assert_match(/mellow\.menu/i, mail.subject)
  end

  test 'subject mentions demo' do
    assert_match(/demo/i, mail.subject)
  end

  # ---------------------------------------------------------------------------
  # ICS attachment
  # ---------------------------------------------------------------------------

  test 'has exactly one attachment' do
    assert_equal 1, mail.attachments.length
  end

  test 'attachment is named demo_booking.ics' do
    assert_equal 'demo_booking.ics', mail.attachments.first.filename
  end

  test 'attachment has text/calendar content type' do
    assert_match 'text/calendar', mail.attachments.first.content_type
  end

  test 'attachment content type specifies METHOD REQUEST' do
    assert_match(/method=REQUEST/i, mail.attachments.first.content_type)
  end

  test 'ICS content includes METHOD:REQUEST' do
    assert_match(/METHOD:REQUEST/i, mail.attachments.first.decoded)
  end

  test 'ICS content includes the contact name in the summary' do
    assert_match 'Jane Smith', mail.attachments.first.decoded
  end

  test 'ICS content includes the prospect email as an attendee' do
    assert_match 'jane@therestaurant.com', mail.attachments.first.decoded
  end

  test 'ICS content includes the demos address as organizer' do
    assert_match 'demos@mellow.menu', mail.attachments.first.decoded
  end

  test 'ICS content includes RSVP=TRUE' do
    assert_match(/RSVP=TRUE/i, mail.attachments.first.decoded)
  end

  # ---------------------------------------------------------------------------
  # HTML body
  # ---------------------------------------------------------------------------

  test 'HTML body includes the contact name' do
    assert_match 'Jane Smith', mail.html_part.body.decoded
  end

  test 'HTML body includes the restaurant name' do
    assert_match 'The Harbour Kitchen', mail.html_part.body.decoded
  end

  test 'HTML body includes a Calendly booking link' do
    assert_match(/calendly\.com/, mail.html_part.body.decoded)
  end

  test 'HTML body uses the branded mailer layout' do
    assert_match(/mellow\.menu/i, mail.html_part.body.decoded)
  end

  test 'HTML body contains Privacy Policy link' do
    assert_match(/Privacy Policy/i, mail.html_part.body.decoded)
  end

  test 'HTML body includes venue type when present' do
    assert_match(/casual/i, mail.html_part.body.decoded)
  end

  test 'HTML body includes a Google Calendar fallback link' do
    assert_match(/calendar\.google\.com/, mail.html_part.body.decoded)
  end

  # ---------------------------------------------------------------------------
  # Plain text body
  # ---------------------------------------------------------------------------

  test 'has a plain-text part' do
    assert_not_nil mail.text_part
  end

  test 'plain-text body includes the contact name' do
    assert_match 'Jane Smith', mail.text_part.body.decoded
  end

  test 'plain-text body includes the restaurant name' do
    assert_match 'The Harbour Kitchen', mail.text_part.body.decoded
  end

  test 'plain-text body includes a Calendly URL' do
    assert_match(/calendly\.com/, mail.text_part.body.decoded)
  end

  test 'plain-text body includes a Google Calendar URL' do
    assert_match(/calendar\.google\.com/, mail.text_part.body.decoded)
  end

  # ---------------------------------------------------------------------------
  # Deliverability
  # ---------------------------------------------------------------------------

  test 'is deliverable without error' do
    assert_nothing_raised { mail.deliver_now }
  end
end

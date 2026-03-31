require 'test_helper'

class ReceiptMailerTest < ActionMailer::TestCase
  def setup
    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)

    @ordr.update_columns(
      status: Ordr.statuses[:paid],
      gross: 24.97,
      tax: 2.25,
      tip: 2.00,
    )

    @delivery = ReceiptDelivery.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      recipient_email: 'diner@example.com',
      delivery_method: 'email',
      status: 'pending',
    )

    ActionMailer::Base.default_url_options[:host] = 'localhost'
    ActionMailer::Base.default_url_options[:port] = 3000
  end

  def mail
    ReceiptMailer.customer_receipt(receipt_delivery: @delivery)
  end

  # ---------------------------------------------------------------------------
  # Envelope
  # ---------------------------------------------------------------------------

  test 'is addressed to the recipient' do
    assert_equal ['diner@example.com'], mail.to
  end

  test 'is sent from the Mellow Menu address' do
    assert_equal ['hello@mellow.menu'], mail.from
  end

  test 'subject contains the restaurant name' do
    assert_match @restaurant.name, mail.subject
  end

  test 'subject includes the word receipt' do
    assert_match(/receipt/i, mail.subject)
  end

  # ---------------------------------------------------------------------------
  # HTML body
  # ---------------------------------------------------------------------------

  test 'HTML body includes the order number' do
    assert_match @ordr.id.to_s, mail.html_part.body.decoded
  end

  test 'HTML body includes the restaurant name' do
    assert_match @restaurant.name, mail.html_part.body.decoded
  end

  test 'HTML body includes the grand total' do
    assert_match(/24/, mail.html_part.body.decoded)
  end

  test 'HTML body includes a Thank you message' do
    assert_match(/Thank you/i, mail.html_part.body.decoded)
  end

  test 'HTML body uses the branded mailer layout (contains mellow.menu)' do
    assert_match(/mellow\.menu/i, mail.html_part.body.decoded)
  end

  test 'HTML body contains branded layout footer with Privacy Policy link' do
    assert_match(/Privacy Policy/i, mail.html_part.body.decoded)
  end

  test 'HTML body does not contain raw card numbers or sensitive payment data' do
    html = mail.html_part.body.decoded
    # Assert no 16-digit card number patterns are present
    assert_no_match(/\b\d{16}\b/, html)
    # Assert no CVV patterns
    assert_no_match(/\b\d{3,4}\b.*cvv/i, html)
  end

  test 'HTML body renders tax row when tax is present' do
    assert_match(/[Tt]ax/, mail.html_part.body.decoded)
  end

  test 'HTML body renders tip row when tip is present' do
    assert_match(/[Tt]ip/, mail.html_part.body.decoded)
  end

  # ---------------------------------------------------------------------------
  # Plain text body
  # ---------------------------------------------------------------------------

  test 'has a plain-text part' do
    assert_not_nil mail.text_part
  end

  test 'plain-text body includes the restaurant name' do
    assert_match @restaurant.name, mail.text_part.body.decoded
  end

  test 'plain-text body includes the order number' do
    assert_match @ordr.id.to_s, mail.text_part.body.decoded
  end

  test 'plain-text body includes Total line' do
    assert_match(/Total:/, mail.text_part.body.decoded)
  end

  # ---------------------------------------------------------------------------
  # Deliverability
  # ---------------------------------------------------------------------------

  test 'is deliverable without error' do
    assert_nothing_raised { mail.deliver_now }
  end
end

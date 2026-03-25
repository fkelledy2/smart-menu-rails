require 'test_helper'

class ReceiptDeliveryTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)
  end

  def build_delivery(overrides = {})
    ReceiptDelivery.new({
      ordr: @ordr,
      restaurant: @restaurant,
      recipient_email: 'customer@example.com',
      delivery_method: 'email',
      status: 'pending',
      retry_count: 0,
    }.merge(overrides))
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test 'valid with all required email attributes' do
    assert build_delivery.valid?
  end

  test 'invalid without ordr' do
    d = build_delivery(ordr: nil)
    assert_not d.valid?
    assert_includes d.errors[:ordr], 'must exist'
  end

  test 'invalid without restaurant' do
    d = build_delivery(restaurant: nil)
    assert_not d.valid?
    assert_includes d.errors[:restaurant], 'must exist'
  end

  test 'invalid with unknown delivery_method' do
    d = build_delivery(delivery_method: 'carrier_pigeon')
    assert_not d.valid?
    assert_includes d.errors[:delivery_method], 'is not included in the list'
  end

  test 'invalid with unknown status' do
    d = build_delivery(status: 'bounced')
    assert_not d.valid?
    assert_includes d.errors[:status], 'is not included in the list'
  end

  test 'invalid without recipient_email when delivery_method is email' do
    d = build_delivery(recipient_email: nil, delivery_method: 'email')
    assert_not d.valid?
    assert_includes d.errors[:recipient_email], "can't be blank"
  end

  test 'invalid with malformed recipient_email' do
    d = build_delivery(recipient_email: 'not-an-email')
    assert_not d.valid?
    assert d.errors[:recipient_email].any?
  end

  test 'valid email format passes validation' do
    assert build_delivery(recipient_email: 'valid+tag@subdomain.example.com').valid?
  end

  test 'invalid without recipient_phone when delivery_method is sms' do
    d = build_delivery(delivery_method: 'sms', recipient_email: nil, recipient_phone: nil)
    assert_not d.valid?
    assert d.errors[:recipient_phone].any?
  end

  test 'secure_token is auto-generated before validation on create' do
    d = build_delivery
    assert_nil d.secure_token
    d.valid?
    assert_not_nil d.secure_token
  end

  test 'secure_token uniqueness is validated' do
    existing = receipt_deliveries(:one)
    d = build_delivery(secure_token: existing.secure_token)
    assert_not d.valid?
    assert_includes d.errors[:secure_token], 'has already been taken'
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test 'pending scope returns only pending deliveries' do
    assert receipt_deliveries(:one).pending?
    assert_includes ReceiptDelivery.pending, receipt_deliveries(:one)
    assert_not_includes ReceiptDelivery.pending, receipt_deliveries(:two)
  end

  test 'sent scope returns only sent deliveries' do
    assert_includes ReceiptDelivery.sent, receipt_deliveries(:two)
    assert_not_includes ReceiptDelivery.sent, receipt_deliveries(:one)
  end

  test 'failed scope returns only failed deliveries' do
    assert_includes ReceiptDelivery.failed, receipt_deliveries(:three)
    assert_not_includes ReceiptDelivery.failed, receipt_deliveries(:one)
  end

  test 'retryable scope excludes deliveries that exceeded max retries' do
    d = build_delivery(status: 'failed', retry_count: ReceiptDelivery::MAX_RETRIES)
    d.save!
    assert_not_includes ReceiptDelivery.retryable, d
  end

  test 'retryable scope includes failed deliveries below max retries' do
    failed = receipt_deliveries(:three)
    assert failed.retry_count < ReceiptDelivery::MAX_RETRIES
    assert_includes ReceiptDelivery.retryable, failed
  end

  test 'for_ordr scope filters by ordr_id' do
    results = ReceiptDelivery.for_ordr(@ordr.id)
    results.each { |d| assert_equal @ordr.id, d.ordr_id }
  end

  # ---------------------------------------------------------------------------
  # Instance methods
  # ---------------------------------------------------------------------------

  test '#mark_sent! sets status to sent and populates sent_at' do
    d = build_delivery
    d.save!
    d.mark_sent!
    assert d.sent?
    assert_not_nil d.sent_at
    assert_nil d.error_message
  end

  test '#mark_failed! sets status to failed and populates error_message' do
    d = build_delivery
    d.save!
    d.mark_failed!('SMTP timeout')
    assert d.failed?
    assert_equal 'SMTP timeout', d.error_message
  end

  test '#mark_failed! truncates very long error messages' do
    d = build_delivery
    d.save!
    d.mark_failed!('x' * 600)
    assert d.error_message.length <= 500
  end

  test '#increment_retry! increments retry_count' do
    d = receipt_deliveries(:three)
    old_count = d.retry_count
    d.increment_retry!
    assert_equal old_count + 1, d.reload.retry_count
  end

  test '#retryable? returns true for failed delivery below max retries' do
    assert receipt_deliveries(:three).retryable?
  end

  test '#retryable? returns false for sent delivery' do
    assert_not receipt_deliveries(:two).retryable?
  end

  test '#retryable? returns false when retry_count equals MAX_RETRIES' do
    d = build_delivery(status: 'failed', retry_count: ReceiptDelivery::MAX_RETRIES)
    d.save!
    assert_not d.retryable?
  end

  test '#sent? returns true only for sent status' do
    assert receipt_deliveries(:two).sent?
    assert_not receipt_deliveries(:one).sent?
  end

  test '#pending? returns true only for pending status' do
    assert receipt_deliveries(:one).pending?
    assert_not receipt_deliveries(:two).pending?
  end

  test '#failed? returns true only for failed status' do
    assert receipt_deliveries(:three).failed?
    assert_not receipt_deliveries(:one).failed?
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test 'belongs to ordr' do
    assert_equal @ordr, receipt_deliveries(:one).ordr
  end

  test 'belongs to restaurant' do
    assert_equal @restaurant, receipt_deliveries(:one).restaurant
  end

  test 'ordr has_many receipt_deliveries' do
    assert_respond_to @ordr, :receipt_deliveries
  end

  test 'restaurant has_many receipt_deliveries' do
    assert_respond_to @restaurant, :receipt_deliveries
  end
end

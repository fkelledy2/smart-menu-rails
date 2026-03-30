require 'test_helper'

class CustomerWaitQueueTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  def build_entry(overrides = {})
    CustomerWaitQueue.new({
      restaurant: @restaurant,
      customer_name: 'Test Party',
      party_size: 4,
      joined_queue_at: Time.current,
      queue_position: 1,
      status: 'waiting',
    }.merge(overrides))
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test 'valid with required attributes' do
    assert build_entry.valid?
  end

  test 'invalid without customer_name' do
    entry = build_entry(customer_name: nil)
    assert_not entry.valid?
    assert_includes entry.errors[:customer_name], "can't be blank"
  end

  test 'invalid with customer_name exceeding 100 characters' do
    entry = build_entry(customer_name: 'A' * 101)
    assert_not entry.valid?
  end

  test 'invalid without party_size' do
    entry = build_entry(party_size: nil)
    assert_not entry.valid?
  end

  test 'invalid with zero party_size' do
    entry = build_entry(party_size: 0)
    assert_not entry.valid?
  end

  test 'invalid with negative party_size' do
    entry = build_entry(party_size: -1)
    assert_not entry.valid?
  end

  test 'invalid without joined_queue_at' do
    entry = build_entry(joined_queue_at: nil)
    assert_not entry.valid?
  end

  test 'invalid without queue_position' do
    entry = build_entry(queue_position: nil)
    assert_not entry.valid?
  end

  test 'invalid with zero queue_position' do
    entry = build_entry(queue_position: 0)
    assert_not entry.valid?
  end

  test 'invalid with invalid status' do
    entry = build_entry(status: 'unknown_status')
    assert_not entry.valid?
    assert_includes entry.errors[:status], 'is not included in the list'
  end

  test 'valid phone format accepted' do
    entry = build_entry(customer_phone: '+1 555-000-0000')
    assert entry.valid?
  end

  test 'invalid phone format rejected' do
    entry = build_entry(customer_phone: 'not-a-phone!!')
    assert_not entry.valid?
  end

  test 'blank phone is valid (optional)' do
    entry = build_entry(customer_phone: '')
    assert entry.valid?
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test 'active scope returns waiting and notified entries' do
    active = CustomerWaitQueue.active
    active.each do |entry|
      assert_includes %w[waiting notified], entry.status
    end
  end

  test 'waiting_only scope returns only waiting entries' do
    CustomerWaitQueue.waiting_only.each do |entry|
      assert_equal 'waiting', entry.status
    end
  end

  test 'by_position scope orders by queue_position ascending' do
    entries = CustomerWaitQueue.active.by_position.to_a
    positions = entries.map(&:queue_position)
    assert_equal positions.sort, positions
  end

  # ---------------------------------------------------------------------------
  # Status predicates
  # ---------------------------------------------------------------------------

  test 'waiting? returns true when status is waiting' do
    entry = build_entry(status: 'waiting')
    assert entry.waiting?
    assert_not entry.seated?
    assert_not entry.terminal?
    assert entry.active?
  end

  test 'seated? returns true when status is seated' do
    entry = build_entry(status: 'seated')
    assert entry.seated?
    assert entry.terminal?
    assert_not entry.active?
  end

  test 'no_show? returns true when status is no_show' do
    entry = build_entry(status: 'no_show')
    assert entry.no_show?
    assert entry.terminal?
  end

  test 'cancelled? returns true when status is cancelled' do
    entry = build_entry(status: 'cancelled')
    assert entry.cancelled?
    assert entry.terminal?
  end

  test 'notified? returns true when status is notified' do
    entry = build_entry(status: 'notified')
    assert entry.notified?
    assert entry.active?
    assert_not entry.terminal?
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test 'belongs to restaurant' do
    entry = customer_wait_queues(:waiting_one)
    assert_equal restaurants(:one), entry.restaurant
  end

  test 'tablesetting is optional' do
    entry = build_entry(tablesetting: nil)
    assert entry.valid?
  end

  # ---------------------------------------------------------------------------
  # Constants
  # ---------------------------------------------------------------------------

  test 'STATUSES includes all expected values' do
    expected = %w[waiting notified seated cancelled no_show]
    assert_equal expected, CustomerWaitQueue::STATUSES
  end

  test 'STANDARD_PARTY_SIZES includes 2, 4, 6, 8' do
    assert_equal [2, 4, 6, 8], CustomerWaitQueue::STANDARD_PARTY_SIZES
  end

  test 'DEFAULT_WAIT_MINUTES is 30' do
    assert_equal 30, CustomerWaitQueue::DEFAULT_WAIT_MINUTES
  end
end

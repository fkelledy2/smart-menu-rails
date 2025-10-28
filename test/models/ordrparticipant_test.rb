require 'test_helper'

class OrdrparticipantTest < ActiveSupport::TestCase
  def setup
    @ordrparticipant = ordrparticipants(:one)
    @ordr = ordrs(:one)
    @employee = employees(:one)
    @ordritem = ordritems(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @ordrparticipant.valid?
  end

  test 'should require sessionid' do
    @ordrparticipant.sessionid = nil
    assert_not @ordrparticipant.valid?
    assert_includes @ordrparticipant.errors[:sessionid], "can't be blank"
  end

  test 'should not require preferredlocale' do
    @ordrparticipant.preferredlocale = nil
    assert @ordrparticipant.valid?
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to ordr' do
    assert_respond_to @ordrparticipant, :ordr
    assert_instance_of Ordr, @ordrparticipant.ordr
  end

  test 'should belong to employee optionally' do
    assert_respond_to @ordrparticipant, :employee
    # Employee can be nil for customer participants
    @ordrparticipant.employee = nil
    assert @ordrparticipant.valid?
  end

  test 'should belong to ordritem optionally' do
    assert_respond_to @ordrparticipant, :ordritem
    # Ordritem can be nil initially
    @ordrparticipant.ordritem = nil
    assert @ordrparticipant.valid?
  end

  test 'should have many ordrparticipant_allergyn_filters' do
    assert_respond_to @ordrparticipant, :ordrparticipant_allergyn_filters
  end

  test 'should have many allergyns through filters' do
    assert_respond_to @ordrparticipant, :allergyns
  end

  # === ENUM TESTS ===

  test 'should have correct role enum values' do
    assert_equal 0, Ordrparticipant.roles[:customer]
    assert_equal 1, Ordrparticipant.roles[:staff]
  end

  test 'should allow role changes' do
    @ordrparticipant.customer!
    assert @ordrparticipant.customer?

    @ordrparticipant.staff!
    assert @ordrparticipant.staff?
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create customer ordrparticipant' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'session_123',
      name: 'John Customer',
      preferredlocale: 'en',
      role: :customer,
      ordr: @ordr,
    )
    assert ordrparticipant.save
    assert_equal 'session_123', ordrparticipant.sessionid
    assert_equal 'John Customer', ordrparticipant.name
    assert_equal 'en', ordrparticipant.preferredlocale
    assert ordrparticipant.customer?
    assert_nil ordrparticipant.employee
  end

  test 'should create staff ordrparticipant' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'staff_session_456',
      name: 'Jane Staff',
      preferredlocale: 'en',
      role: :staff,
      ordr: @ordr,
      employee: @employee,
    )
    assert ordrparticipant.save
    assert ordrparticipant.staff?
    assert_equal @employee, ordrparticipant.employee
  end

  test 'should create ordrparticipant with ordritem' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'session_with_item',
      name: 'Customer with Item',
      role: :customer,
      ordr: @ordr,
      ordritem: @ordritem,
    )
    assert ordrparticipant.save
    assert_equal @ordritem, ordrparticipant.ordritem
  end

  test 'should create ordrparticipant without preferredlocale' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'session_no_locale',
      name: 'No Locale Customer',
      role: :customer,
      ordr: @ordr,
    )
    assert ordrparticipant.save
    assert_nil ordrparticipant.preferredlocale
  end

  test 'should create ordrparticipant with different session ids' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'unique_session_789',
      name: 'Unique Customer',
      role: :customer,
      ordr: @ordr,
    )
    assert ordrparticipant.save
    assert_equal 'unique_session_789', ordrparticipant.sessionid
  end

  # === DEPENDENT DESTROY TESTS ===

  test 'should have correct dependent destroy configuration' do
    reflection = Ordrparticipant.reflect_on_association(:ordrparticipant_allergyn_filters)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Ordrparticipant.respond_to?(:cache_index)
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle customer without employee' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'customer_session',
      name: 'Anonymous Customer',
      role: :customer,
      ordr: @ordr,
      employee: nil,
    )
    assert ordrparticipant.save
    assert ordrparticipant.customer?
    assert_nil ordrparticipant.employee
  end

  test 'should handle staff with employee' do
    ordrparticipant = Ordrparticipant.new(
      sessionid: 'staff_session',
      name: 'Staff Member',
      role: :staff,
      ordr: @ordr,
      employee: @employee,
    )
    assert ordrparticipant.save
    assert ordrparticipant.staff?
    assert_equal @employee, ordrparticipant.employee
  end
end

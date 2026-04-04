# frozen_string_literal: true

require 'test_helper'

class DemoBookingTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test 'is valid with all required attributes' do
    booking = DemoBooking.new(
      restaurant_name: 'The Harbour Kitchen',
      contact_name: 'Jane Smith',
      email: 'jane@therestaurant.com',
      conversion_status: 'pending',
    )
    assert booking.valid?
  end

  test 'is invalid without restaurant_name' do
    booking = DemoBooking.new(contact_name: 'Jane', email: 'jane@example.com')
    assert_not booking.valid?
    assert_includes booking.errors[:restaurant_name], "can't be blank"
  end

  test 'is invalid without contact_name' do
    booking = DemoBooking.new(restaurant_name: 'Restaurant', email: 'jane@example.com')
    assert_not booking.valid?
    assert_includes booking.errors[:contact_name], "can't be blank"
  end

  test 'is invalid without email' do
    booking = DemoBooking.new(restaurant_name: 'Restaurant', contact_name: 'Jane')
    assert_not booking.valid?
    assert_includes booking.errors[:email], "can't be blank"
  end

  test 'is invalid with malformed email' do
    booking = DemoBooking.new(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: 'not-an-email',
    )
    assert_not booking.valid?
    assert booking.errors[:email].any?
  end

  test 'is invalid with unknown restaurant_type' do
    booking = DemoBooking.new(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: 'jane@example.com',
      restaurant_type: 'spaceship_diner',
    )
    assert_not booking.valid?
    assert booking.errors[:restaurant_type].any?
  end

  test 'is valid with blank restaurant_type' do
    booking = DemoBooking.new(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: 'jane@example.com',
      restaurant_type: '',
    )
    assert booking.valid?
  end

  test 'is invalid with unknown conversion_status' do
    booking = DemoBooking.new(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: 'jane@example.com',
      conversion_status: 'unknown_status',
    )
    assert_not booking.valid?
  end

  test 'is invalid with interests over 2000 characters' do
    booking = DemoBooking.new(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: 'jane@example.com',
      interests: 'a' * 2001,
    )
    assert_not booking.valid?
  end

  # ---------------------------------------------------------------------------
  # Email normalisation
  # ---------------------------------------------------------------------------

  test 'downcases email before validation' do
    booking = DemoBooking.create!(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: 'JANE@EXAMPLE.COM',
    )
    assert_equal 'jane@example.com', booking.email
  end

  test 'strips whitespace from email' do
    booking = DemoBooking.create!(
      restaurant_name: 'Restaurant',
      contact_name: 'Jane',
      email: '  jane@example.com  ',
    )
    assert_equal 'jane@example.com', booking.email
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test '.pending returns only pending bookings' do
    pending_count = DemoBooking.pending.count
    assert pending_count >= 1
    DemoBooking.pending.each do |b|
      assert_equal 'pending', b.conversion_status
    end
  end

  test '.recent orders by created_at descending' do
    dates = DemoBooking.recent.pluck(:created_at)
    assert_equal dates.sort.reverse, dates
  end

  test '.by_email finds by downcased email' do
    booking = demo_bookings(:pending_lead)
    results = DemoBooking.by_email('JANE@THERESTAURANT.COM')
    assert_includes results, booking
  end

  # ---------------------------------------------------------------------------
  # calendly_booking_url
  # ---------------------------------------------------------------------------

  test 'calendly_booking_url includes name and email' do
    booking = demo_bookings(:pending_lead)
    url = booking.calendly_booking_url
    assert_match(/name=/, url)
    assert_match(/email=/, url)
  end

  test 'calendly_booking_url includes restaurant name' do
    booking = demo_bookings(:pending_lead)
    url = booking.calendly_booking_url
    assert_match(/The\+Harbour\+Kitchen|The%20Harbour%20Kitchen/, url)
  end

  test 'calendly_booking_url returns valid URL even without env var' do
    original = ENV.delete('CALENDLY_EVENT_URL')
    booking = demo_bookings(:pending_lead)
    url = booking.calendly_booking_url
    assert_match(%r{https://calendly\.com}, url)
  ensure
    ENV['CALENDLY_EVENT_URL'] = original if original
  end

  # ---------------------------------------------------------------------------
  # CRM lead integration — create_or_advance_crm_lead after_create
  # ---------------------------------------------------------------------------

  test 'creating a DemoBooking auto-creates a CrmLead when no matching email exists' do
    assert_difference 'CrmLead.count', 1 do
      DemoBooking.create!(
        restaurant_name: 'New Demo Restaurant',
        contact_name: 'Brand New Contact',
        email: 'brand_new_demo@newrestaurant.com',
      )
    end

    lead = CrmLead.find_by(contact_email: 'brand_new_demo@newrestaurant.com')
    assert_not_nil lead
    assert_equal 'demo_booked', lead.stage
    assert_equal 'website', lead.source
    assert_equal 'New Demo Restaurant', lead.restaurant_name
  end

  test 'auto-created CrmLead from DemoBooking writes a lead_created audit' do
    assert_difference 'CrmLeadAudit.count', 1 do
      DemoBooking.create!(
        restaurant_name: 'Audit Demo Restaurant',
        contact_name: 'Audit Contact',
        email: 'audit_demo_unique@newrestaurant.com',
      )
    end

    lead = CrmLead.find_by(contact_email: 'audit_demo_unique@newrestaurant.com')
    audit = lead.crm_lead_audits.order(:created_at).last
    assert_equal 'lead_created', audit.event
    assert_equal 'system', audit.actor_type
  end

  test 'creating a DemoBooking advances an existing CrmLead to demo_booked' do
    # contacted_lead is in 'contacted' stage and has matching email 'pierre@lamaison.fr'
    lead = crm_leads(:contacted_lead)
    assert_equal 'contacted', lead.stage

    assert_no_difference 'CrmLead.count' do
      DemoBooking.create!(
        restaurant_name: lead.restaurant_name,
        contact_name: lead.contact_name,
        email: lead.contact_email,
      )
    end

    assert_equal 'demo_booked', lead.reload.stage
  end

  test 'creating a DemoBooking does not regress an already-converted lead' do
    lead = crm_leads(:converted_lead)
    assert_equal 'converted', lead.stage

    DemoBooking.create!(
      restaurant_name: lead.restaurant_name,
      contact_name: lead.contact_name,
      email: lead.contact_email,
    )

    assert_equal 'converted', lead.reload.stage
  end

  test 'creating a DemoBooking does not regress a demo_booked lead' do
    lead = crm_leads(:demo_booked_lead)
    assert_equal 'demo_booked', lead.stage

    DemoBooking.create!(
      restaurant_name: lead.restaurant_name,
      contact_name: lead.contact_name,
      email: lead.contact_email,
    )

    assert_equal 'demo_booked', lead.reload.stage
  end

  test 'creating a DemoBooking does not advance a lost lead' do
    lead = crm_leads(:lost_lead)
    assert_equal 'lost', lead.stage

    assert_no_difference 'CrmLead.count' do
      DemoBooking.create!(
        restaurant_name: lead.restaurant_name,
        contact_name: lead.contact_name,
        email: lead.contact_email,
      )
    end

    assert_equal 'lost', lead.reload.stage
  end

  test 'CrmLead created from DemoBooking copies contact_phone' do
    DemoBooking.create!(
      restaurant_name: 'Phone Test Restaurant',
      contact_name: 'Phone Test',
      email: 'phone_test_unique@phonedemo.com',
      phone: '+353 1 234 5678',
    )

    lead = CrmLead.find_by(contact_email: 'phone_test_unique@phonedemo.com')
    assert_equal '+353 1 234 5678', lead.contact_phone
  end

  # ---------------------------------------------------------------------------
  # Fixtures
  # ---------------------------------------------------------------------------

  test 'fixture pending_lead is valid' do
    assert demo_bookings(:pending_lead).valid?
  end

  test 'fixture converted_lead has correct status' do
    assert_equal 'converted', demo_bookings(:converted_lead).conversion_status
  end
end

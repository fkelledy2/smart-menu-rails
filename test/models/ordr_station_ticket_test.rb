# frozen_string_literal: true

require 'test_helper'

class OrdrStationTicketTest < ActiveSupport::TestCase
  def build_ticket(overrides = {})
    OrdrStationTicket.new({
      restaurant: restaurants(:one),
      ordr: ordrs(:one),
      station: :kitchen,
      status: :ordered,
      sequence: SecureRandom.random_number(9_999_999),
    }.merge(overrides))
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is valid with all required attributes' do
    ActionCable.server.stub(:broadcast, nil) do
      ticket = build_ticket
      assert ticket.valid?, ticket.errors.full_messages.join(', ')
    end
  end

  test 'is invalid without station' do
    ticket = build_ticket
    ticket.station = nil
    # Setting nil on an enum field may still be valid if DB has default;
    # test through ActiveRecord clearing
    ticket.write_attribute(:station, nil)
    assert_not ticket.valid?
    assert ticket.errors[:station].any?
  end

  test 'is invalid without status' do
    ticket = build_ticket
    ticket.write_attribute(:status, nil)
    assert_not ticket.valid?
    assert ticket.errors[:status].any?
  end

  test 'is invalid without sequence' do
    ticket = build_ticket(sequence: nil)
    assert_not ticket.valid?
    assert ticket.errors[:sequence].any?
  end

  test 'sequence must be unique per ordr and station' do
    seq = SecureRandom.random_number(99_999)

    ActionCable.server.stub(:broadcast, nil) do
      first = build_ticket(sequence: seq)
      first.save!

      second = build_ticket(sequence: seq, station: :kitchen)
      second.ordr = first.ordr
      second.restaurant = first.restaurant
      assert_not second.valid?
      assert second.errors[:sequence].any?
    end
  end

  test 'same sequence allowed for different stations' do
    seq = SecureRandom.random_number(99_999)

    ActionCable.server.stub(:broadcast, nil) do
      kitchen = build_ticket(sequence: seq, station: :kitchen)
      kitchen.save!

      bar = build_ticket(sequence: seq, station: :bar)
      bar.ordr = kitchen.ordr
      bar.restaurant = kitchen.restaurant
      assert bar.valid?
    end
  end

  # =========================================================================
  # enums
  # =========================================================================

  test 'station enum has kitchen and bar' do
    assert build_ticket(station: :kitchen).kitchen?
    assert build_ticket(station: :bar).bar?
  end

  test 'status enum has ordered preparing ready collected' do
    %i[ordered preparing ready collected].each do |s|
      ticket = build_ticket(status: s)
      assert_equal s.to_s, ticket.status
    end
  end

  # =========================================================================
  # associations
  # =========================================================================

  test 'belongs to restaurant' do
    ticket = build_ticket
    assert_equal restaurants(:one), ticket.restaurant
  end

  test 'belongs to ordr' do
    ticket = build_ticket
    assert_equal ordrs(:one), ticket.ordr
  end
end

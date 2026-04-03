# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::ReadCustomerPreferencesTest < ActiveSupport::TestCase
  def setup
    @smartmenu = smartmenus(:one)
  end

  test 'tool_name is read_customer_preferences' do
    assert_equal 'read_customer_preferences', Agents::Tools::ReadCustomerPreferences.tool_name
  end

  test 'description is present' do
    assert Agents::Tools::ReadCustomerPreferences.description.present?
  end

  test 'input_schema requires smartmenu_id' do
    schema = Agents::Tools::ReadCustomerPreferences.input_schema
    assert_includes schema[:required], 'smartmenu_id'
  end

  test 'call with no sessionid returns defaults' do
    result = Agents::Tools::ReadCustomerPreferences.call(
      'smartmenu_id' => @smartmenu.id,
    )

    assert_equal 'en', result[:locale]
    assert_equal [], result[:excluded_allergyn_ids]
    assert_equal false, result[:has_dietary_restrictions]
  end

  test 'call with unknown sessionid returns defaults' do
    result = Agents::Tools::ReadCustomerPreferences.call(
      'smartmenu_id' => @smartmenu.id,
      'sessionid' => 'nonexistent-session-token',
    )

    assert_equal 'en', result[:locale]
    assert_equal [], result[:excluded_allergyn_ids]
  end

  test 'call returns preferred locale from menuparticipant' do
    participant = Menuparticipant.find_or_create_by!(
      smartmenu: @smartmenu,
      sessionid: 'test-session-concierge-pref',
    ) do |p|
      p.preferredlocale = 'fr'
    end

    result = Agents::Tools::ReadCustomerPreferences.call(
      'smartmenu_id' => @smartmenu.id,
      'sessionid' => 'test-session-concierge-pref',
    )

    assert_equal 'fr', result[:locale]
  ensure
    participant&.destroy
  end

  test 'call returns allergen IDs from ordrparticipant filters' do
    allergyn   = allergyns(:one)
    restaurant = @smartmenu.menu&.restaurant
    return skip('Smartmenu has no restaurant') unless restaurant

    tablesetting = Tablesetting.where(restaurant: restaurant).first
    return skip('No tablesetting for restaurant') unless tablesetting

    ordr = begin
      Ordr.create!(
        restaurant: restaurant,
        tablesetting: tablesetting,
        status: :opened,
        subtotal: 0,
        total: 0,
        smartmenu: @smartmenu,
      )
    rescue StandardError
      skip('Cannot create Ordr for test setup')
    end

    ordrparticipant = Ordrparticipant.create!(
      ordr: ordr,
      sessionid: 'test-session-allergen',
      role: :customer,
    )

    OrdrparticipantAllergynFilter.create!(
      ordrparticipant: ordrparticipant,
      allergyn: allergyn,
    )

    result = Agents::Tools::ReadCustomerPreferences.call(
      'smartmenu_id' => @smartmenu.id,
      'sessionid' => 'test-session-allergen',
    )

    assert_includes result[:excluded_allergyn_ids], allergyn.id
    assert result[:has_dietary_restrictions]
  ensure
    OrdrparticipantAllergynFilter.where(ordrparticipant: ordrparticipant).destroy_all if ordrparticipant
    ordrparticipant&.destroy
    ordr&.destroy
  end
end

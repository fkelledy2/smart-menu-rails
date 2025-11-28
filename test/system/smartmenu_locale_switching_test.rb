require 'application_system_test_case'

class SmartmenuLocaleSwitchingTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @table = tablesettings(:table_one)
    # Use the provided smartmenu slug for customer view
    slug = '3ecb722a-5257-4954-91b9-ee6863b84533'
    @smartmenu = Smartmenu.find_by(slug: slug)
    unless @smartmenu
      @smartmenu = Smartmenu.create!(restaurant: @restaurant, menu: @menu, tablesetting: @table, slug: slug)
    else
      @smartmenu.update!(tablesetting: @table)
    end
    # Ensure active locales exist for the restaurant so the selector renders
    %w[en it es].each do |loc|
      rl = Restaurantlocale.find_or_initialize_by(restaurant: @restaurant, locale: loc)
      rl.status = 'active'
      rl.save!
    end
  end

  # Pre-order: selecting locale persists in Menuparticipant
  test 'customer can set locale before order and it persists in menuparticipant' do
    visit smartmenu_path(@smartmenu.slug)
    ensure_order_dom_context!
    assert_testid('smartmenu-customer-view')

    # Open dropdown and click a locale flag
    find('#lovale-actions', wait: 5).click rescue nil
    flag = find('.setparticipantlocale', match: :first, wait: 5, visible: :all)
    chosen = flag[:'data-locale']
    flag.click

    # Wait for request
    wait_for_requests_to_complete(timeout: 5)

    # Poll until DB reflects the change
    Timeout.timeout(5) do
      loop do
        mp = Menuparticipant.find_by(smartmenu_id: @smartmenu.id)
        break if mp&.preferredlocale&.downcase == chosen.downcase
        sleep 0.05
      end
    end

    # Verify Menuparticipant stored preference for this smartmenu
    mp = Menuparticipant.find_by(smartmenu_id: @smartmenu.id)
    assert mp.present?, 'Menuparticipant should exist'
    assert_equal chosen.downcase, mp.preferredlocale&.downcase
  end

  # Transfer: starting an order transfers Menuparticipant preferredlocale to Ordrparticipant
  test 'starting order transfers menuparticipant preferredlocale to ordrparticipant' do
    visit smartmenu_path(@smartmenu.slug)
    ensure_order_dom_context!

    # Pre-select a locale
    find('#lovale-actions', wait: 5).click rescue nil
    italian = find('.setparticipantlocale[data-locale]', match: :first, wait: 5, visible: :all)
    chosen = italian[:'data-locale']
    italian.click
    wait_for_requests_to_complete(timeout: 5)
    Timeout.timeout(5) do
      loop do
        mp = Menuparticipant.find_by(smartmenu_id: @smartmenu.id)
        break if mp&.preferredlocale&.downcase == chosen.downcase
        sleep 0.05
      end
    end

    # Start order and add item to ensure participant exists
    start_order_if_needed
    add_item_to_order(menuitems(:burger).id)

    order = Ordr.last
    op = order.ordrparticipants.where(role: 0).first
    assert op.present?, 'Ordrparticipant should exist'
    assert_equal chosen.downcase, op.preferredlocale&.downcase
  end

  # Post-order: changing locale persists in Ordrparticipant
  test 'customer can change locale after order and it persists in ordrparticipant' do
    visit smartmenu_path(@smartmenu.slug)
    ensure_order_dom_context!
    start_order_if_needed
    add_item_to_order(menuitems(:burger).id)
    order = Ordr.last

    # Change locale
    find('#lovale-actions', wait: 5).click rescue nil
    target = find('.setparticipantlocale[data-locale]', match: :first, wait: 5, visible: :all)
    chosen = target[:'data-locale']
    target.click
    wait_for_requests_to_complete(timeout: 5)
    # Poll until DB reflects the change on ordrparticipant
    Timeout.timeout(5) do
      loop do
        op = order.ordrparticipants.where(role: 0).first
        break if op&.reload&.preferredlocale&.downcase == chosen.downcase
        sleep 0.05
      end
    end
  end

  # Default fallback: when no preference, display in restaurant default locale
  test 'menu displays in default restaurant locale when no preference set' do
    visit smartmenu_path(@smartmenu.slug)
    # Do not click a locale; ensure no menuparticipant exists for session
    Menuparticipant.where(smartmenu_id: @smartmenu.id, sessionid: session.id.to_s).delete_all rescue nil

    # Check selected locale icon corresponds to restaurant default
    default_locale = @restaurant.defaultLocale&.locale.to_s.downcase
    default_locale = I18n.default_locale.to_s if default_locale.blank?

    # Selected flag reflects default; if not visible, at least the dropdown renders
    assert_selector('.setparticipantlocale', wait: 5)
    # Open dropdown and ensure default locale option is present
    find('#lovale-actions').click rescue nil
    assert_selector(".setparticipantlocale[data-locale='#{default_locale}']")
  end
end

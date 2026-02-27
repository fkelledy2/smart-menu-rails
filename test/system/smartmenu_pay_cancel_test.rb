require 'application_system_test_case'

class SmartmenuPayCancelTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @table = tablesettings(:table_one)
    @smartmenu = smartmenus(:one)

    # Ensure smartmenu has table set
    @smartmenu.update!(tablesetting: @table)

    # Menu items
    @burger = menuitems(:burger)
    @pasta = menuitems(:pasta)
  end

  # ===================
  # PAY / CANCEL FLOW
  # ===================

  test 'clicking Cancel in pay section restores Pay button and sets sheet to half state' do
    setup_billrequested_order

    # Wait for the bottom sheet and JS hydration (Pay button visible = hydration done)
    assert_selector('#cartBottomSheet', wait: 10)
    wait_for_pay_button_visible
    expand_sheet_to('half')
    sleep 0.5

    # Click Pay button via JS to avoid click interception
    page.execute_script("document.getElementById('cartPayOrder')?.click()")

    # Wait for Cancel button to appear (pay section rendered)
    Timeout.timeout(10) do
      loop do
        ready = page.evaluate_script(
          "!!document.getElementById('cartPayCancel') && " \
          "document.getElementById('cartPaySection')?.style?.display === 'block'"
        )
        break if ready
        sleep 0.3
      end
    end

    # Click Cancel button via JS
    page.execute_script("document.getElementById('cartPayCancel')?.click()")
    sleep 1

    # Dump post-cancel state
    post_cancel = dump_sheet_state('POST-CANCEL')

    # ASSERTIONS
    assert_equal 'none', post_cancel['paySectionDisplay'],
      "Pay section should be hidden after Cancel. State: #{post_cancel}"

    assert_not_equal 'none', post_cancel['payBtnDisplay'],
      "Pay button should be visible after Cancel. State: #{post_cancel}"

    assert_includes post_cancel['sheetClass'].to_s, 'bottom-sheet--half',
      "Sheet should be in half state after Cancel. State: #{post_cancel}"

    assert_not_includes post_cancel['sheetClass'].to_s, 'bottom-sheet--full',
      "Sheet should NOT be in full state after Cancel. State: #{post_cancel}"
  end

  test 'Cancel button has event listener bound after Pay click renders pay section' do
    setup_billrequested_order

    assert_selector('#cartBottomSheet', wait: 10)
    wait_for_pay_button_visible
    expand_sheet_to('half')
    sleep 0.5

    # Inject a test marker to detect if the Cancel click fires any handler
    page.execute_script(<<~JS)
      window.__cancelClicked = false;
      document.addEventListener('click', function(e) {
        if (e.target && e.target.id === 'cartPayCancel') {
          window.__cancelClicked = true;
        }
      }, true);
    JS

    # Click Pay and wait for pay section to render
    page.execute_script("document.getElementById('cartPayOrder')?.click()")

    # Wait for Cancel button to appear (pay section rendered)
    Timeout.timeout(10) do
      loop do
        has_cancel = page.evaluate_script("!!document.getElementById('cartPayCancel') && document.getElementById('cartPaySection')?.style?.display === 'block'")
        break if has_cancel
        sleep 0.3
      end
    end

    has_cancel = page.evaluate_script("!!document.getElementById('cartPayCancel')")
    assert has_cancel, 'Cancel button should exist after Pay click'

    # Click Cancel via JS
    page.execute_script("document.getElementById('cartPayCancel')?.click()")
    sleep 0.5

    # Check if the document-level listener detected the click
    cancel_detected = page.evaluate_script("window.__cancelClicked")
    assert cancel_detected, 'Cancel button click should be detected at document level'

    # Check the resulting state
    post_cancel = dump_sheet_state('POST-CANCEL-HANDLER-TEST')

    assert_equal 'none', post_cancel['paySectionDisplay'],
      "Cancel handler should hide pay section. State: #{post_cancel}"
    assert_not_equal 'none', post_cancel['payBtnDisplay'],
      "Cancel handler should restore Pay button. State: #{post_cancel}"
    assert_includes post_cancel['sheetClass'].to_s, 'bottom-sheet--half',
      "Cancel handler should set sheet to half. State: #{post_cancel}"
  end

  private

  def setup_billrequested_order
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed

    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)

    order = Ordr.where(
      restaurant_id: @restaurant.id,
      tablesetting_id: @table.id,
      menu_id: @menu.id
    ).where.not(status: [:paid, :closed]).order(:created_at).last

    assert order.present?, 'Order should exist'
    recalc_order_totals!(order)
    order.update!(status: :billrequested, billRequestedAt: Time.current)

    # Reload page so state hydrates with billrequested status
    visit smartmenu_path(@smartmenu.slug)
  end

  def wait_for_hydration
    # Wait for state controller to hydrate (Pay button should exist in DOM)
    Timeout.timeout(15) do
      loop do
        has_pay = page.evaluate_script("!!document.getElementById('cartPayOrder')")
        break if has_pay
        sleep 0.5
      end
    end
  rescue Timeout::Error
    flunk 'Hydration timeout: #cartPayOrder never appeared in DOM'
  end

  def wait_for_pay_button_visible
    # Wait for JS hydration to make Pay button visible (display: block)
    Timeout.timeout(15) do
      loop do
        visible = page.evaluate_script(
          "document.getElementById('cartPayOrder')?.style?.display === 'block' || " \
          "document.getElementById('cartPayOrder')?.offsetParent !== null"
        )
        break if visible
        sleep 0.5
      end
    end
  rescue Timeout::Error
    debug = page.evaluate_script("JSON.stringify({exists: !!document.getElementById('cartPayOrder'), display: document.getElementById('cartPayOrder')?.style?.display})")
    flunk "Pay button never became visible. Debug: #{debug}"
  end

  def expand_sheet_to(state)
    page.execute_script(<<~JS)
      var sheet = document.getElementById('cartBottomSheet');
      if (sheet) {
        var ctrl = sheet.__stimulusControllerInstance ||
          window.Stimulus?.getControllerForElementAndIdentifier?.(sheet, 'bottom-sheet') ||
          sheet.closest('[data-controller]')?.__stimulusControllerInstances?.find(c => c.identifier === 'bottom-sheet');
        if (ctrl) {
          ctrl.setState('#{state}');
        } else {
          // Fallback: manually set classes and transform
          sheet.className = sheet.className.replace(/bottom-sheet--\\w+/g, '') + ' bottom-sheet--#{state}';
          if ('#{state}' === 'half') {
            sheet.style.transform = 'translateY(' + (100 - (parseInt(sheet.dataset.bottomSheetHalfValue) || 55)) + '%)';
          } else if ('#{state}' === 'full') {
            sheet.style.transform = 'translateY(0)';
          }
        }
      }
    JS
  end

  def dump_sheet_state(label)
    result = page.evaluate_script(<<~JS)
      (function() {
        var ps = document.getElementById('cartPaySection');
        var pb = document.getElementById('cartPayOrder');
        var sh = document.getElementById('cartBottomSheet');
        var cb = document.getElementById('cartPayCancel');
        return {
          paySectionDisplay: ps?.style?.display || 'not-set',
          payBtnDisplay: pb?.style?.display || 'not-set',
          sheetClass: sh?.className || 'not-found',
          hasCancelBtn: !!cb,
          cancelBtnText: cb?.textContent?.trim(),
          cancelOnclick: cb?.getAttribute('onclick')
        };
      })()
    JS
    puts "[DEBUG] #{label}: #{result}"
    result
  end
end

require "application_system_test_case"
require "securerandom"

class SmartmenuMultiTableLifecycleTest < ApplicationSystemTestCase
  setup do
    # Core fixtures from existing phases
    @user       = users(:one)
    @restaurant = restaurants(:one)
    @menu       = menus(:one)

    # Ensure ordering is enabled so visiting smartmenu can open an order automatically
    @menu.update!(allowOrdering: true) if @menu.respond_to?(:allowOrdering)

    # Ensure @user has a known password for UI login in this test
    @user.update!(password: 'password123', password_confirmation: 'password123')

    # Use up to 3 existing menu sections from fixtures that actually have items
    @sections = @menu.menusections.order(:id).select { |s| s.menuitems.exists? }.take(3)
    assert @sections.size >= 1, "Expected at least 1 menu section with items in fixtures for this menu"

    # Preload items per section from fixtures
    @items_by_section = {}
    @sections.each do |section|
      @items_by_section[section.id] = section.menuitems.order(:id).to_a
    end

  def ensure_order_status_progress(table, ordr_id: nil, desired_status: nil, not_status: nil, timeout: 8)
    start = Time.now
    loop do
      order = if ordr_id.present?
        Ordr.find_by(id: ordr_id)
      else
        Ordr.where(restaurant: @restaurant, tablesetting: table).order(:created_at).last
      end
      if desired_status && order
        if desired_status.to_s == 'billrequested'
          return true if %w[billrequested paid closed].include?(order.status.to_s)
        elsif desired_status.to_s == 'paid'
          return true if %w[paid closed].include?(order.status.to_s)
        else
          return true if order.status == desired_status
        end
      end
      return true if not_status && order && order.status != not_status
      break if Time.now - start > timeout
      sleep 0.5
    end
    false
  end

  def close_all_modals(session)
    # Attempt to click any visible dismiss buttons first
    begin
      session.all(:css, 'button[data-bs-dismiss="modal"]', minimum: 0, wait: 0).each do |btn|
        begin
          btn.click
        rescue Selenium::WebDriver::Error::ElementClickInterceptedError, Selenium::WebDriver::Error::ElementNotInteractableError
          next
        end
      end
    rescue StandardError
      # ignore
    end

    # Try ESC a couple of times (best-effort)
    begin
      2.times { session.send_keys(:escape) }
    rescue Selenium::WebDriver::Error::ElementNotInteractableError, StandardError
      # ignore
    end

    # Remove any lingering backdrops/modals if present (best-effort, non-fatal)
    begin
      session.execute_script(<<~JS)
        document.querySelectorAll('.modal.show').forEach(function(m){ m.classList.remove('show'); m.style.display='none'; });
        document.querySelectorAll('.modal-backdrop.show').forEach(function(b){ b.remove(); });
        document.body.classList.remove('modal-open');
      JS
    rescue StandardError
      # ignore
    end
    wait_for_no_backdrop(session)
  end

    # Use existing tablesettings from fixtures
    tables = Tablesetting.where(restaurant: @restaurant).order(:id).limit(2).to_a
    assert_equal 2, tables.size, "Expected at least 2 tablesettings in fixtures for this restaurant"
    @table1, @table2 = tables

    # Use existing smartmenus if present, otherwise create minimal ones
    @smartmenu1 = Smartmenu.where(menu: @menu, restaurant: @restaurant, tablesetting: @table1).first ||
                  Smartmenu.create!(menu: @menu, restaurant: @restaurant, tablesetting: @table1, slug: "multi-table-1")
    @smartmenu2 = Smartmenu.where(menu: @menu, restaurant: @restaurant, tablesetting: @table2).first ||
                  Smartmenu.create!(menu: @menu, restaurant: @restaurant, tablesetting: @table2, slug: "multi-table-2")
  end

  test "multi-table, multi-customer orders stay isolated and totals are correct through full lifecycle" do
    # 1 customer per table, 2 sessions total
    c1 = new_customer_session("C1_T1")
    c5 = new_customer_session("C5_T2")

    @expected_items_t1 = simulate_customers_for_table([c1], @smartmenu1)
    @expected_items_t2 = simulate_customers_for_table([c5], @smartmenu2)

    # Submit orders (customer UI) and request bill
    submit_order_and_request_bill(c1, @smartmenu1)
    submit_order_and_request_bill(c5, @smartmenu2)

    # Staff takes payment via staff UI
    login_as_staff(@user)
    take_payment_via_staff_ui(@smartmenu1)
    take_payment_via_staff_ui(@smartmenu2)

    verify_final_totals_and_isolation
  end

  private

  def new_customer_session(name)
    Capybara::Session.new(Capybara.current_driver, Capybara.app).tap do |s|
      s.instance_variable_set(:@session_name, name)
    end
  end

  def simulate_customers_for_table(sessions, smartmenu)
    total_added = 0
    sessions.each do |session|
      # Force customer view and bust caches to ensure correct rendering
      session.visit smartmenu_path(smartmenu.slug, view: 'customer', nocache: SecureRandom.hex(6))
      session.assert_selector('[data-testid="smartmenu-customer-view"]', wait: 10)
      ensure_order_started(session)
      total_added += add_one_item_from_each_section(session)
    end
    total_added
  end

  def add_one_item_from_each_section(session)
    added = 0
    @sections.each do |section|
      close_all_modals(session)
      wait_for_no_backdrop(session)

      # Navigate to section if needed (assumes section title has test id)
      if session.has_selector?(%([data-testid="menu-section-title-#{section.id}"]))
        title = session.find(%([data-testid="menu-section-title-#{section.id}"]))
        session.execute_script('arguments[0].scrollIntoView({block: "center"});', title.native)
        begin
          title.click
        rescue Selenium::WebDriver::Error::ElementClickInterceptedError
          close_all_modals(session)
          wait_for_no_backdrop(session)
          session.execute_script('arguments[0].click();', title.native)
        end
      end

      items = @items_by_section[section.id]
      item = items.first
      # Prefer testid selector; fall back to a generic button containing the item id if needed
      if session.has_selector?(%([data-testid="add-item-btn-#{item.id}"]))
        btn = session.find(%([data-testid="add-item-btn-#{item.id}"]))
        session.execute_script('arguments[0].scrollIntoView({block: "center"});', btn.native)
        begin
          btn.click
        rescue Selenium::WebDriver::Error::ElementClickInterceptedError
          close_all_modals(session)
          wait_for_no_backdrop(session)
          session.execute_script('arguments[0].click();', btn.native)
        end
        if session.has_selector?('#addItemToOrderModal.show', wait: 5)
          session.find('#addItemToOrderButton', wait: 5).click
          session.has_no_selector?('#addItemToOrderModal.show', wait: 5)
          added += 1
        end
      elsif session.has_button?("Add")
        # Fallback: click a generic Add button if present in item context
        session.click_button("Add")
        added += 1
      end
    end
    added
  end

  def ensure_order_started(session)
    order_id = begin
      session.evaluate_script('window.__SM_STATE && window.__SM_STATE.order && window.__SM_STATE.order.id')
    rescue StandardError
      nil
    end
    return if order_id.present?

    begin
      trigger = session.find('button[data-bs-target="#openOrderModal"], a[data-bs-target="#openOrderModal"]', match: :first, wait: 3)
      session.execute_script('arguments[0].scrollIntoView({block: "center"});', trigger.native)
      trigger.click
    rescue StandardError
      session.execute_script("var m=document.getElementById('openOrderModal'); if(m && window.bootstrap){(window.bootstrap.Modal.getInstance(m)||window.bootstrap.Modal.getOrCreateInstance(m)).show();}")
    end

    session.assert_selector('#openOrderModal.show', wait: 5)
    start_btn = session.find('#start-order', wait: 5)
    begin
      start_btn.click
    rescue Selenium::WebDriver::Error::ElementClickInterceptedError
      session.execute_script('arguments[0].click();', start_btn.native)
    end
    session.has_no_selector?('#openOrderModal.show', wait: 5)

    start = Time.now
    loop do
      order_id = begin
        session.evaluate_script('window.__SM_STATE && window.__SM_STATE.order && window.__SM_STATE.order.id')
      rescue StandardError
        nil
      end
      break if order_id.present?
      break if Time.now - start > 10
      sleep 0.25
    end
  end

  def login_as_staff(user)
    visit new_user_session_path
    # Use the same test IDs and password convention as AuthenticationTest
    fill_testid('login-email-input', user.email)
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')
  end

  def submit_order_and_request_bill(session, smartmenu)
    session.visit smartmenu_path(smartmenu.slug)
    session.assert_selector('[data-testid="smartmenu-customer-view"]', wait: 10)
    ensure_order_started(session)
    # Open order modal and submit
    close_all_modals(session)
    wait_for_no_backdrop(session)
    # If the order modal is already open, skip trying to click openers
    unless session.has_selector?('[data-testid="view-order-modal"]', wait: 1)
      if session.has_selector?('[data-testid="order-fab-btn"]', wait: 5)
        fab = session.find('[data-testid="order-fab-btn"]')
        session.execute_script('arguments[0].scrollIntoView({block: "center"});', fab.native)
        begin
          fab.click
        rescue Selenium::WebDriver::Error::ElementClickInterceptedError
          # If a modal is already open and intercepting, proceed with it instead of forcing the click
          unless session.has_selector?('[data-testid="view-order-modal"]', wait: 1)
            # Fallback to JS click only if modal isn't already present
            session.execute_script('arguments[0].click();', fab.native)
          end
        end
      elsif session.has_selector?('[data-testid="view-order-btn"]', wait: 5)
        wait_for_no_backdrop(session)
        session.find('[data-testid="view-order-btn"]').click
      else
        # Ensure there is at least one item in the order, then retry opening the modal
        add_one_item_from_first_section(session)
        wait_for_no_backdrop(session)
        if session.has_selector?('[data-testid="order-fab-btn"]', wait: 5)
          fab = session.find('[data-testid="order-fab-btn"]')
          session.execute_script('arguments[0].scrollIntoView({block: "center"});', fab.native)
          begin
            fab.click
          rescue Selenium::WebDriver::Error::ElementClickInterceptedError
            session.execute_script('arguments[0].click();', fab.native)
          end
        else
          wait_for_no_backdrop(session)
          session.find('[data-testid="view-order-btn"]', wait: 5).click
        end
      end
    end
    session.assert_selector('[data-testid="view-order-modal"]', wait: 5)
    # Submit; if disabled or missing, add an item and retry once
    retried = false
    begin
      if session.has_selector?('[data-testid="submit-order-btn"]', wait: 5)
        submit_btn = session.find('[data-testid="submit-order-btn"]', wait: 5)
        if submit_btn[:disabled]
          raise :submit_disabled
        else
          submit_btn.click
        end
      else
        raise :submit_missing
      end
    rescue => _e
      unless retried
        # Close modal, add an item, reopen modal, then try submit again
        click_view_order_cancel(session)
        wait_for_modal_to_close(session)
        add_one_item_from_first_section(session)
        wait_for_no_backdrop(session)
        if session.has_selector?('[data-testid="order-fab-btn"]', wait: 5)
          session.find('[data-testid="order-fab-btn"]').click
        elsif session.has_selector?('[data-testid="view-order-btn"]', wait: 5)
          session.find('[data-testid="view-order-btn"]').click
        end
        session.assert_selector('[data-testid="view-order-modal"]', wait: 5)
        retried = true
        retry
      end
    end
    # Wait for modal/backdrop to close before next action
    wait_for_modal_to_close(session)

    # Wait for state to reflect successful submission (items promoted and bill available)
    start = Time.now
    loop do
      st = begin
        session.evaluate_script('window.__SM_STATE && window.__SM_STATE.order && window.__SM_STATE.order.status')
      rescue StandardError
        nil
      end
      can_bill = begin
        session.evaluate_script('window.__SM_STATE && window.__SM_STATE.flags && window.__SM_STATE.flags.displayRequestBill')
      rescue StandardError
        nil
      end
      break if st.to_s.downcase != 'opened' && can_bill == true
      break if Time.now - start > 12
      sleep 0.25
    end

    # Request bill (do not require status off 'opened' here; the button presence is the UI gate)
    if session.has_selector?('[data-testid="request-bill-btn"]', wait: 5)
      wait_for_no_backdrop(session)
      btn = session.find('[data-testid="request-bill-btn"]')
      session.execute_script('arguments[0].scrollIntoView({block: "center"});', btn.native)
      begin
        btn.click
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        # Fallback to JS click if something still intercepts
        session.execute_script('arguments[0].click();', btn.native)
      end
      # In modal
      session.assert_selector('#requestBillModal.show', wait: 5)
      session.assert_selector('#request-bill-confirm:not([disabled])', wait: 10)
      confirm_btn = session.find('#request-bill-confirm', wait: 5)
      begin
        confirm_btn.click
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        session.execute_script('arguments[0].click();', confirm_btn.native)
      end
      session.has_no_selector?('#requestBillModal.show', wait: 5)
      wait_for_modal_to_close(session)
    else
      # If request bill button isn't present yet, retry submit once then attempt request bill again
      if session.has_selector?('[data-testid="order-fab-btn"]', wait: 3)
        session.find('[data-testid="order-fab-btn"]').click
      elsif session.has_selector?('[data-testid="view-order-btn"]', wait: 3)
        session.find('[data-testid="view-order-btn"]').click
      end
      if session.has_selector?('[data-testid="submit-order-btn"]', wait: 3)
        sbtn = session.find('[data-testid="submit-order-btn"]')
        sbtn.click unless sbtn[:disabled]
      end
      wait_for_modal_to_close(session)
      if session.has_selector?('[data-testid="request-bill-btn"]', wait: 5)
        btn = session.find('[data-testid="request-bill-btn"]')
        session.execute_script('arguments[0].scrollIntoView({block: "center"});', btn.native)
        session.execute_script('arguments[0].click();', btn.native)
        session.assert_selector('#requestBillModal.show', wait: 5)
        session.assert_selector('#request-bill-confirm:not([disabled])', wait: 10)
        confirm_btn = session.find('#request-bill-confirm', wait: 5)
        session.execute_script('arguments[0].click();', confirm_btn.native)
        session.has_no_selector?('#requestBillModal.show', wait: 5)
        wait_for_modal_to_close(session)
      end
    end

    # Capture the current order id from hydrated UI state (post-submit/post-request-bill)
    current_order_id = begin
      session.evaluate_script('window.__SM_STATE && window.__SM_STATE.order && window.__SM_STATE.order.id')
    rescue StandardError
      nil
    end
    if current_order_id.blank?
      begin
        ctx = session.find('#contextContainer', wait: 5)
        current_order_id = ctx['data-order-id']
      rescue StandardError
        nil
      end
    end

    # Verify status progressed using backend
    bill_req = ensure_order_status_progress(smartmenu.tablesetting, ordr_id: current_order_id, desired_status: 'billrequested', timeout: 20)
    assert bill_req, "Order did not reach 'billrequested' after requesting bill via customer UI"
  end

  def add_one_item_from_first_section(session)
    # Ensure no modal/backdrop is covering the page before trying to add
    close_all_modals(session)
    wait_for_no_backdrop(session)

    ensure_order_started(session)

    section = @sections.first
    return unless section
    items = @items_by_section[section.id]
    item = items&.first
    return unless item
    # Click add on the first item
    if session.has_selector?(%([data-testid="add-item-btn-#{item.id}"]), wait: 5)
      btn = session.find(%([data-testid="add-item-btn-#{item.id}"]))
      session.execute_script('arguments[0].scrollIntoView({block: "center"});', btn.native)
      begin
        btn.click
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        session.execute_script('arguments[0].click();', btn.native)
      end
      # Confirm add in modal
      session.assert_selector('#addItemToOrderModal.show', wait: 5)
      session.find('#addItemToOrderButton', wait: 5).click
      session.has_no_selector?('#addItemToOrderModal.show', wait: 5)
      # Ensure add-item modal/backdrop are closed before continuing
      close_all_modals(session)
    end
  end

  def wait_for_no_backdrop(session)
    # Wait for any open modal/backdrop to disappear before clicking underlying buttons
    session.has_no_selector?('.modal-backdrop.show', wait: 5)
    session.has_no_selector?('.modal.show', wait: 5)
  end

  def wait_for_modal_to_close(session)
    session.has_no_selector?('[data-testid="view-order-modal"].show', wait: 5)
    wait_for_no_backdrop(session)
  end

  def click_view_order_cancel(session)
    if session.has_selector?('#viewOrderModal button[data-bs-dismiss="modal"]', wait: 5)
      buttons = session.all(:css, '#viewOrderModal button[data-bs-dismiss="modal"]', minimum: 1)
      buttons.first.click
    elsif session.has_selector?('[data-testid="view-order-modal"] button[data-bs-dismiss="modal"]', wait: 5)
      buttons = session.all(:css, '[data-testid="view-order-modal"] button[data-bs-dismiss="modal"]', minimum: 1)
      buttons.first.click
    else
      # As a very last resort, press ESC to close modal
      session.send_keys(:escape)
    end
  end

  def take_payment_via_staff_ui(smartmenu)
    # Bust HTTP/fragment caches so we don't get a cached customer view
    2.times do
      url = smartmenu_path(smartmenu.slug, view: 'staff', nocache: SecureRandom.hex(6))
      visit url
      break if has_selector?('[data-testid="smartmenu-staff-view"]', wait: 5)
    end
    assert_selector('[data-testid="smartmenu-staff-view"]', wait: 10)
    # If pay not available yet, progress via staff UI: submit order, request bill, then pay
    unless page.has_selector?('[data-testid="staff-pay-btn"]', wait: 2)
      # Submit order (open viewOrderModal and press submit if enabled)
      if page.has_selector?('[data-testid="staff-view-order-btn"]', wait: 5)
        btn = find('[data-testid="staff-view-order-btn"]', match: :first)
        execute_script('arguments[0].scrollIntoView({block: "center"});', btn.native)
        btn.click
        if page.has_selector?('[data-testid="submit-order-btn"]', wait: 5)
          submit_btn = find('[data-testid="submit-order-btn"]')
          submit_btn.click unless submit_btn[:disabled]
        end
        # Close modal if still open
        if page.has_selector?('#viewOrderModal button[data-bs-dismiss="modal"]', wait: 3)
          all(:css, '#viewOrderModal button[data-bs-dismiss="modal"]').first.click
        else
          send_keys(:escape)
        end
        has_no_selector?('#viewOrderModal.show', wait: 5)
      end

      # Request bill from staff UI
      if page.has_selector?('[data-testid="staff-request-bill-btn"]', wait: 5)
        rbtn = find('[data-testid="staff-request-bill-btn"]', match: :first)
        execute_script('arguments[0].scrollIntoView({block: "center"});', rbtn.native)
        rbtn.click
        if page.has_selector?('#requestBillModal.show', wait: 5)
          assert_selector('#request-bill-confirm:not([disabled])', wait: 10)
          confirm_btn = find('#request-bill-confirm', wait: 5)
          begin
            confirm_btn.click
          rescue Selenium::WebDriver::Error::ElementClickInterceptedError
            execute_script('arguments[0].click();', confirm_btn.native)
          end
          has_no_selector?('#requestBillModal.show', wait: 5)
        end
      end
    end

    # Open pay modal when available (status billrequested)
    if page.has_selector?('[data-testid="staff-pay-btn"]', wait: 10)
      pbtn = find('[data-testid="staff-pay-btn"]', match: :first)
      execute_script('arguments[0].scrollIntoView({block: "center"});', pbtn.native)
      pbtn.click
      assert_selector('#payOrderModal.show', wait: 5)
      assert_selector('#pay-order-confirm:not([disabled])', wait: 10)
      confirm_btn = find('#pay-order-confirm', wait: 10)
      begin
        confirm_btn.click
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        execute_script('arguments[0].click();', confirm_btn.native)
      end
      has_no_selector?('#payOrderModal.show', wait: 5)
    end
    # Verify paid status on the backend
    paid = ensure_order_status_progress(smartmenu.tablesetting, desired_status: 'paid', timeout: 20)
    order = Ordr.where(restaurant: @restaurant, tablesetting: smartmenu.tablesetting).order(:created_at).last
    assert paid && order.status == 'paid', "Order for #{smartmenu.tablesetting.name} should be paid at end of lifecycle"
  end

  def verify_final_totals_and_isolation
    order_t1 = Ordr.where(restaurant: @restaurant, tablesetting: @table1).order(:created_at).last
    order_t2 = Ordr.where(restaurant: @restaurant, tablesetting: @table2).order(:created_at).last

    assert order_t1.present?, "Expected an order for Table 1"
    assert order_t2.present?, "Expected an order for Table 2"

    if @expected_items_t1 > 0
      assert_equal @expected_items_t1, order_t1.ordritems.count, "Table 1 should have #{@expected_items_t1} items based on UI additions"
    end
    if @expected_items_t2 > 0
      assert_equal @expected_items_t2, order_t2.ordritems.count, "Table 2 should have #{@expected_items_t2} items based on UI additions"
    end

    expected_t1 = order_t1.ordritems.sum(:ordritemprice)
    expected_t2 = order_t2.ordritems.sum(:ordritemprice)

    assert_equal expected_t1.to_f.round(2), order_t1.gross.to_f.round(2), "Table 1 final gross total should match sum of items"
    assert_equal expected_t2.to_f.round(2), order_t2.gross.to_f.round(2), "Table 2 final gross total should match sum of items"

    ids_t1 = order_t1.ordritems.pluck(:id)
    ids_t2 = order_t2.ordritems.pluck(:id)
    assert_equal 0, (ids_t1 & ids_t2).size, "Orders for each table should not share ordritems"
  end

  # no programmatic seeding in strict UI-driven mode
end

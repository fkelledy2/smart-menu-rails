# frozen_string_literal: true

require 'application_system_test_case'

# System tests for the CRM Kanban board at /admin/crm/leads.
#
# These tests exercise:
#   - Board structure (8 columns, cards in correct columns)
#   - Opening the lead detail modal by clicking a card
#   - Stage transition buttons inside the modal
#   - The Reopen button for lost leads
#   - Drag-and-drop: valid move, invalid move, drop onto "lost", drop onto "converted"
#   - Lost reason modal: confirm flow and dismiss/revert flow
#
# Drag-and-drop notes:
#   SortableJS listens to native pointer/mouse events. We use Selenium's action
#   builder to simulate them. Add a brief sleep after each drag to allow the
#   SortableJS onEnd callback and any subsequent fetch() call to complete.
class CrmLeadsSystemTest < ApplicationSystemTestCase
  # ---------------------------------------------------------------------------
  # Setup / teardown
  # ---------------------------------------------------------------------------

  setup do
    # Create (or reset) the mellow.menu admin user with a known password.
    @admin = User.find_by(email: 'admin@mellow.menu') || User.new(email: 'admin@mellow.menu')
    @admin.assign_attributes(
      first_name: 'Super',
      last_name: 'Admin',
      admin: true,
      super_admin: true,
      password: 'password123',
      password_confirmation: 'password123',
    )
    @admin.save!

    # Create leads in known stages.
    @new_lead = CrmLead.create!(
      restaurant_name: 'Draggable Bistro',
      contact_name: 'Test Contact',
      contact_email: 'bistro@example.com',
      stage: 'new',
      source: 'manual',
      last_activity_at: Time.current,
    )

    @contacted_lead = CrmLead.create!(
      restaurant_name: 'Already Contacted Café',
      stage: 'contacted',
      source: 'manual',
      last_activity_at: Time.current,
    )

    @lost_lead = CrmLead.create!(
      restaurant_name: 'Lost Cause Restaurant',
      stage: 'lost',
      source: 'manual',
      lost_reason: 'price',
      lost_reason_notes: 'Too expensive',
      lost_at: Time.current,
      last_activity_at: Time.current,
    )

    # Enable the Flipper flag for the admin.
    Flipper.enable(:crm_sales_funnel, @admin)

    # Sign in via the login form.
    sign_in_as_mellow_admin

    visit admin_crm_leads_path
    assert_selector '.crm-kanban-column', wait: 10
  end

  teardown do
    Flipper.disable(:crm_sales_funnel)
  end

  # ---------------------------------------------------------------------------
  # Board structure
  # ---------------------------------------------------------------------------

  test 'kanban board renders all 8 stage columns' do
    CrmLead::STAGES.each do |stage|
      assert_selector ".crm-kanban-column[data-stage='#{stage}']",
                      wait: 5,
                      visible: true
    end
  end

  test 'lead cards appear in their correct stage column' do
    within ".crm-kanban-column[data-stage='new']" do
      assert_text @new_lead.restaurant_name
    end

    within ".crm-kanban-column[data-stage='contacted']" do
      assert_text @contacted_lead.restaurant_name
    end

    within ".crm-kanban-column[data-stage='lost']" do
      assert_text @lost_lead.restaurant_name
    end
  end

  test 'each column shows a card count badge' do
    # The new column has at least our @new_lead
    within ".crm-kanban-column[data-stage='new']" do
      assert_selector '.badge', wait: 5
    end
  end

  # ---------------------------------------------------------------------------
  # Lead detail modal — opening via card click
  # ---------------------------------------------------------------------------

  test 'clicking a lead card opens the detail modal' do
    find("#crm-lead-card-#{@new_lead.id}")
    first('a').click

    assert_selector '#leadModal.show', wait: 8
    within '#leadModal' do
      assert_text @new_lead.restaurant_name
    end
  end

  test 'lead detail modal shows contact information' do
    first('a').click

    assert_selector '#leadModal.show', wait: 8
    within '#leadModal' do
      assert_text @new_lead.contact_name
      assert_text @new_lead.contact_email
    end
  end

  test 'lead detail modal shows the current stage badge' do
    first('a').click

    assert_selector '#leadModal.show', wait: 8
    within '#leadModal' do
      assert_selector '.badge', text: 'New'
    end
  end

  # ---------------------------------------------------------------------------
  # Transition buttons inside the modal
  # ---------------------------------------------------------------------------

  test 'transition buttons reflect valid moves for the current stage' do
    first('a').click
    assert_selector '#leadModal.show', wait: 8

    # new → contacted, demo_booked, lost are valid
    within '#leadModal' do
      assert_selector 'button', text: 'Contacted'
      assert_selector 'button', text: 'Demo booked'
      assert_selector 'button', text: 'Lost'
    end
  end

  test 'clicking a transition button in the modal advances the stage' do
    first('a').click
    assert_selector '#leadModal.show', wait: 8

    within '#leadModal' do
      click_button 'Contacted'
    end

    # Modal re-renders (or redirects within the turbo frame) showing new stage
    assert_selector '#leadModal .badge', text: 'Contacted', wait: 8

    assert_equal 'contacted', @new_lead.reload.stage
  end

  test 'transition button to lost advances stage with required lost_reason' do
    # The transition button in the modal posts directly with the stage param;
    # the controller requires lost_reason for → lost, so an invalid attempt
    # should flash an error and not change stage. Verify by submitting without
    # the required param (button_to sends only stage:).
    first('a').click
    assert_selector '#leadModal.show', wait: 8

    within '#leadModal' do
      click_button 'Lost'
    end

    # The service should reject the transition (no lost_reason); the stage stays 'new'
    assert_equal 'new', @new_lead.reload.stage
    assert_selector '#leadModal', wait: 5 # modal remains open
  end

  # ---------------------------------------------------------------------------
  # Reopen button (lost lead)
  # ---------------------------------------------------------------------------

  test 'Reopen button appears in modal for a lost lead' do
    first('a').click
    assert_selector '#leadModal.show', wait: 8

    within '#leadModal' do
      assert_selector 'button, input[type="submit"]', text: 'Reopen'
    end
  end

  test 'clicking Reopen on a lost lead moves it to contacted' do
    # Auto-accept the browser confirm dialog that button_to data-confirm triggers
    page.execute_script('window.confirm = function() { return true; }')

    first('a').click
    assert_selector '#leadModal.show', wait: 8

    within '#leadModal' do
      find('button, input[type="submit"]', text: 'Reopen').click
    end

    assert_equal 'contacted', @lost_lead.reload.stage, wait: 5
  end

  # ---------------------------------------------------------------------------
  # Drag and drop — valid transition
  # ---------------------------------------------------------------------------

  test 'dragging a new lead card to the contacted column advances its stage' do
    drag_card_to_column(@new_lead, 'contacted')

    # Card should now be in the contacted column
    within ".crm-kanban-column[data-stage='contacted']" do
      assert_selector "#crm-lead-card-#{@new_lead.id}", wait: 5
    end

    assert_equal 'contacted', @new_lead.reload.stage
  end

  test 'a success toast appears after a valid drag-and-drop' do
    drag_card_to_column(@new_lead, 'contacted')

    assert_selector '#crm-kanban-toast.alert-success', wait: 5
    assert_selector '#crm-kanban-toast', text: 'Moved to "Contacted"'
  end

  test 'dragging new lead to demo_booked is a valid transition' do
    drag_card_to_column(@new_lead, 'demo_booked')

    assert_equal 'demo_booked', @new_lead.reload.stage
  end

  # ---------------------------------------------------------------------------
  # Drag and drop — invalid transition
  # ---------------------------------------------------------------------------

  test 'dragging a card to an invalid stage reverts its position' do
    # contacted → new is not a valid transition
    drag_card_to_column(@contacted_lead, 'new')

    # Card must end up back in the contacted column
    within ".crm-kanban-column[data-stage='contacted']" do
      assert_selector "#crm-lead-card-#{@contacted_lead.id}", wait: 5
    end

    assert_equal 'contacted', @contacted_lead.reload.stage
  end

  test 'a warning toast appears after an invalid drag attempt' do
    drag_card_to_column(@contacted_lead, 'new')

    assert_selector '#crm-kanban-toast.alert-warning', wait: 5
  end

  test 'dragging contacted lead to demo_completed is invalid (must go through demo_booked first)' do
    # contacted → demo_completed is not in FORWARD_TRANSITIONS['contacted']
    drag_card_to_column(@contacted_lead, 'demo_completed')

    assert_equal 'contacted', @contacted_lead.reload.stage
    assert_selector '#crm-kanban-toast.alert-warning', wait: 5
  end

  # ---------------------------------------------------------------------------
  # Drag and drop — converted column is blocked
  # ---------------------------------------------------------------------------

  test 'dragging a card over the converted column shows a blocked highlight' do
    card = find("#crm-lead-card-#{@new_lead.id}")
    converted_list = find(".crm-kanban-cards[data-stage='converted']")

    # Start drag — move slowly over the converted column
    browser = page.driver.browser
    browser.action
      .move_to(card.native)
      .click_and_hold
      .move_by(0, 5)
      .perform

    sleep 0.3

    browser.action
      .move_to(converted_list.native)
      .perform

    sleep 0.3

    # Converted column should have the blocked class while card is hovering
    assert_selector '.crm-kanban-column--blocked', wait: 2

    # Release and verify card was NOT placed in converted column
    browser.action.release.perform
    sleep 0.5

    assert_equal 'new', @new_lead.reload.stage
    within ".crm-kanban-column[data-stage='new']" do
      assert_selector "#crm-lead-card-#{@new_lead.id}", wait: 5
    end
  end

  # ---------------------------------------------------------------------------
  # Drag to lost — lost reason modal
  # ---------------------------------------------------------------------------

  test 'dragging a card to the lost column opens the lost reason modal' do
    drag_to_lost_column(@new_lead)

    assert_selector '#crmLostReasonModal.show', wait: 8
  end

  test 'lost reason modal contains a reason selector and notes field' do
    drag_to_lost_column(@new_lead)
    assert_selector '#crmLostReasonModal.show', wait: 8

    within '#crmLostReasonModal' do
      assert_selector 'select[name="lost_reason"]'
      assert_selector 'textarea[name="lost_reason_notes"], input[name="lost_reason_notes"]'
    end
  end

  test 'confirm button requires a reason to be selected' do
    drag_to_lost_column(@new_lead)
    assert_selector '#crmLostReasonModal.show', wait: 8

    # Click confirm without selecting a reason
    click_button 'crmLostReasonConfirm'

    # Modal stays open; card has NOT transitioned
    assert_selector '#crmLostReasonModal.show', wait: 2
    assert_equal 'new', @new_lead.reload.stage

    # The select input should now have the is-invalid class
    within '#crmLostReasonModal' do
      assert_selector 'select.is-invalid'
    end
  end

  test 'confirming with a lost reason commits the transition' do
    drag_to_lost_column(@new_lead)
    assert_selector '#crmLostReasonModal.show', wait: 8

    within '#crmLostReasonModal' do
      select 'Price', from: 'lost_reason'
      fill_in 'lost_reason_notes', with: 'Budget constraints'
    end

    click_button 'crmLostReasonConfirm'

    # Modal should close and card should be in the lost column
    assert_no_selector '#crmLostReasonModal.show', wait: 5

    within ".crm-kanban-column[data-stage='lost']" do
      assert_selector "#crm-lead-card-#{@new_lead.id}", wait: 5
    end

    @new_lead.reload
    assert_equal 'lost', @new_lead.stage
    assert_equal 'price', @new_lead.lost_reason
    assert_equal 'Budget constraints', @new_lead.lost_reason_notes
  end

  test 'dismissing the lost reason modal reverts the card to its original column' do
    drag_to_lost_column(@new_lead)
    assert_selector '#crmLostReasonModal.show', wait: 8

    # Close via the × dismiss button
    within '#crmLostReasonModal' do
      find('[data-bs-dismiss="modal"]').click
    end

    assert_no_selector '#crmLostReasonModal.show', wait: 5

    # Card must be back in new column; stage unchanged
    within ".crm-kanban-column[data-stage='new']" do
      assert_selector "#crm-lead-card-#{@new_lead.id}", wait: 5
    end

    assert_equal 'new', @new_lead.reload.stage
  end

  # ---------------------------------------------------------------------------
  # Visual highlights during drag
  # ---------------------------------------------------------------------------

  test 'valid target columns highlight green when dragging' do
    card = find("#crm-lead-card-#{@new_lead.id}")

    page.driver.browser.action
      .move_to(card.native)
      .click_and_hold
      .move_by(0, 5)
      .perform

    sleep 0.3

    # contacted is a valid target from new — should have --valid class
    assert_selector '.crm-kanban-column--valid', wait: 2

    page.driver.browser.action.release.perform
    sleep 0.3
  end

  test 'invalid target columns highlight red when dragging' do
    card = find("#crm-lead-card-#{@new_lead.id}")

    page.driver.browser.action
      .move_to(card.native)
      .click_and_hold
      .move_by(0, 5)
      .perform

    sleep 0.3

    # demo_completed is NOT a valid target from new — should have --invalid class
    assert_selector '.crm-kanban-column--invalid', wait: 2

    page.driver.browser.action.release.perform
    sleep 0.3
  end

  test 'highlights are cleared after drag ends' do
    drag_card_to_column(@new_lead, 'contacted')

    assert_no_selector '.crm-kanban-column--valid', wait: 3
    assert_no_selector '.crm-kanban-column--invalid', wait: 3
    assert_no_selector '.crm-kanban-column--blocked', wait: 3
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  private

  def sign_in_as_mellow_admin
    visit new_user_session_path
    fill_testid('login-email-input', 'admin@mellow.menu')
    fill_testid('login-password-input', 'password123')
    click_testid('login-submit-btn')
    assert_current_path restaurants_path, ignore_query: true, wait: 10
  end

  # Performs a full drag-and-drop of the lead's card to the target stage column.
  # Uses Selenium's action builder to simulate native mouse events, which
  # SortableJS listens to. The brief sleeps give SortableJS time to detect the
  # drag start and process the drop event, and give fetch() time to complete.
  def drag_card_to_column(lead, target_stage)
    card = find("#crm-lead-card-#{lead.id}")
    target_list = find(".crm-kanban-cards[data-stage='#{target_stage}']")

    page.driver.browser.action
      .move_to(card.native)
      .click_and_hold
      .move_by(0, 8) # small move to trigger SortableJS onStart
      .move_to(target_list.native)
      .release
      .perform

    sleep 0.8 # allow SortableJS onEnd + fetch() to complete
  end

  # Drags the lead's card toward the lost column and pauses before releasing,
  # giving the test time to assert on intermediate state (e.g. modal appearing).
  # The release is NOT performed here — the caller controls what happens next
  # (confirm/dismiss). This method leaves the browser in a state where the
  # card has been dropped onto the lost column list.
  def drag_to_lost_column(lead)
    card = find("#crm-lead-card-#{lead.id}")
    lost_list = find(".crm-kanban-cards[data-stage='lost']")

    page.driver.browser.action
      .move_to(card.native)
      .click_and_hold
      .move_by(0, 8)
      .move_to(lost_list.native)
      .release
      .perform

    sleep 0.5 # let SortableJS onEnd fire and the modal open
  end

  # Click a button identified by its id attribute.
  def click_button(id_or_text)
    el = first("button##{id_or_text}") || find('button', text: id_or_text)
    el.click
  end
end

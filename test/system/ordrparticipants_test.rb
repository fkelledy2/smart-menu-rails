require 'application_system_test_case'

class OrdrparticipantsTest < ApplicationSystemTestCase
  setup do
    @ordrparticipant = ordrparticipants(:one)
  end

  test 'visiting the index' do
    visit ordrparticipants_url
    assert_selector 'h1', text: 'Ordrparticipants'
  end

  test 'should create ordrparticipant' do
    visit ordrparticipants_url
    click_on 'New ordrparticipant'

    fill_in 'Action', with: @ordrparticipant.action
    fill_in 'Employee', with: @ordrparticipant.employee_id
    fill_in 'Ordr', with: @ordrparticipant.ordr_id
    fill_in 'Ordritem', with: @ordrparticipant.ordritem_id
    fill_in 'Role', with: @ordrparticipant.role
    fill_in 'Sessionid', with: @ordrparticipant.sessionid
    click_on 'Create Ordrparticipant'

    assert_text 'Ordrparticipant was successfully created'
    click_on 'Back'
  end

  test 'should update Ordrparticipant' do
    visit ordrparticipant_url(@ordrparticipant)
    click_on 'Edit this ordrparticipant', match: :first

    fill_in 'Action', with: @ordrparticipant.action
    fill_in 'Employee', with: @ordrparticipant.employee_id
    fill_in 'Ordr', with: @ordrparticipant.ordr_id
    fill_in 'Ordritem', with: @ordrparticipant.ordritem_id
    fill_in 'Role', with: @ordrparticipant.role
    fill_in 'Sessionid', with: @ordrparticipant.sessionid
    click_on 'Update Ordrparticipant'

    assert_text 'Ordrparticipant was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Ordrparticipant' do
    visit ordrparticipant_url(@ordrparticipant)
    click_on 'Destroy this ordrparticipant', match: :first

    assert_text 'Ordrparticipant was successfully destroyed'
  end
end

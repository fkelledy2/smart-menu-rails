require 'application_system_test_case'

class AllergynsTest < ApplicationSystemTestCase
  setup do
    @allergyn = allergyns(:one)
  end

  test 'visiting the index' do
    visit allergyns_url
    assert_selector 'h1', text: 'Allergyns'
  end

  test 'should create allergyn' do
    visit allergyns_url
    click_on 'New allergyn'

    fill_in 'Description', with: @allergyn.description
    fill_in 'Menuitem', with: @allergyn.menuitem_id
    fill_in 'Name', with: @allergyn.name
    fill_in 'Symbol', with: @allergyn.symbol
    click_on 'Create Allergyn'

    assert_text 'Allergyn was successfully created'
    click_on 'Back'
  end

  test 'should update Allergyn' do
    visit allergyn_url(@allergyn)
    click_on 'Edit this allergyn', match: :first

    fill_in 'Description', with: @allergyn.description
    fill_in 'Menuitem', with: @allergyn.menuitem_id
    fill_in 'Name', with: @allergyn.name
    fill_in 'Symbol', with: @allergyn.symbol
    click_on 'Update Allergyn'

    assert_text 'Allergyn was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Allergyn' do
    visit allergyn_url(@allergyn)
    click_on 'Destroy this allergyn', match: :first

    assert_text 'Allergyn was successfully destroyed'
  end
end

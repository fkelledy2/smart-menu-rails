require 'application_system_test_case'

class MenuavailabilitiesTest < ApplicationSystemTestCase
  setup do
    @menuavailability = menuavailabilities(:one)
  end

  test 'visiting the index' do
    visit menuavailabilities_url
    assert_selector 'h1', text: 'Menuavailabilities'
  end

  test 'should create menuavailability' do
    visit menuavailabilities_url
    click_on 'New menuavailability'

    fill_in 'Dayofweek', with: @menuavailability.dayofweek
    fill_in 'Endhour', with: @menuavailability.endhour
    fill_in 'Endmin', with: @menuavailability.endmin
    fill_in 'Menu', with: @menuavailability.menu_id
    fill_in 'Starthour', with: @menuavailability.starthour
    fill_in 'Startmin', with: @menuavailability.startmin
    click_on 'Create Menuavailability'

    assert_text 'Menuavailability was successfully created'
    click_on 'Back'
  end

  test 'should update Menuavailability' do
    visit menuavailability_url(@menuavailability)
    click_on 'Edit this menuavailability', match: :first

    fill_in 'Dayofweek', with: @menuavailability.dayofweek
    fill_in 'Endhour', with: @menuavailability.endhour
    fill_in 'Endmin', with: @menuavailability.endmin
    fill_in 'Menu', with: @menuavailability.menu_id
    fill_in 'Starthour', with: @menuavailability.starthour
    fill_in 'Startmin', with: @menuavailability.startmin
    click_on 'Update Menuavailability'

    assert_text 'Menuavailability was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Menuavailability' do
    visit menuavailability_url(@menuavailability)
    click_on 'Destroy this menuavailability', match: :first

    assert_text 'Menuavailability was successfully destroyed'
  end
end

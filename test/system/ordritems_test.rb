require 'application_system_test_case'

class OrdritemsTest < ApplicationSystemTestCase
  setup do
    @ordritem = ordritems(:one)
  end

  test 'visiting the index' do
    visit ordritems_url
    assert_selector 'h1', text: 'Ordritems'
  end

  test 'should create ordritem' do
    visit ordritems_url
    click_on 'New ordritem'

    fill_in 'Menuitem', with: @ordritem.menuitem_id
    fill_in 'Ordr', with: @ordritem.ordr_id
    click_on 'Create Ordritem'

    assert_text 'Ordritem was successfully created'
    click_on 'Back'
  end

  test 'should update Ordritem' do
    visit ordritem_url(@ordritem)
    click_on 'Edit this ordritem', match: :first

    fill_in 'Menuitem', with: @ordritem.menuitem_id
    fill_in 'Ordr', with: @ordritem.ordr_id
    click_on 'Update Ordritem'

    assert_text 'Ordritem was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Ordritem' do
    visit ordritem_url(@ordritem)
    click_on 'Destroy this ordritem', match: :first

    assert_text 'Ordritem was successfully destroyed'
  end
end

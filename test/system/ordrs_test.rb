require 'application_system_test_case'

class OrdrsTest < ApplicationSystemTestCase
  setup do
    @ordr = ordrs(:one)
  end

  test 'visiting the index' do
    visit ordrs_url
    assert_selector 'h1', text: 'Ordrs'
  end

  test 'should create ordr' do
    visit ordrs_url
    click_on 'New ordr'

    fill_in 'Deliveredat', with: @ordr.deliveredAt
    fill_in 'Employee', with: @ordr.employee_id
    fill_in 'Gross', with: @ordr.gross
    fill_in 'Menu', with: @ordr.menu_id
    fill_in 'Nett', with: @ordr.nett
    fill_in 'Orderedat', with: @ordr.orderedAt
    fill_in 'Paidat', with: @ordr.paidAt
    fill_in 'Restaurant', with: @ordr.restaurant_id
    fill_in 'Service', with: @ordr.service
    fill_in 'Tablesetting', with: @ordr.tablesetting_id
    fill_in 'Tax', with: @ordr.tax
    fill_in 'Tip', with: @ordr.tip
    click_on 'Create Ordr'

    assert_text 'Ordr was successfully created'
    click_on 'Back'
  end

  test 'should update Ordr' do
    visit ordr_url(@ordr)
    click_on 'Edit this ordr', match: :first

    fill_in 'Deliveredat', with: @ordr.deliveredAt
    fill_in 'Employee', with: @ordr.employee_id
    fill_in 'Gross', with: @ordr.gross
    fill_in 'Menu', with: @ordr.menu_id
    fill_in 'Nett', with: @ordr.nett
    fill_in 'Orderedat', with: @ordr.orderedAt
    fill_in 'Paidat', with: @ordr.paidAt
    fill_in 'Restaurant', with: @ordr.restaurant_id
    fill_in 'Service', with: @ordr.service
    fill_in 'Tablesetting', with: @ordr.tablesetting_id
    fill_in 'Tax', with: @ordr.tax
    fill_in 'Tip', with: @ordr.tip
    click_on 'Update Ordr'

    assert_text 'Ordr was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Ordr' do
    visit ordr_url(@ordr)
    click_on 'Destroy this ordr', match: :first

    assert_text 'Ordr was successfully destroyed'
  end
end

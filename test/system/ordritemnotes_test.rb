require "application_system_test_case"

class OrdritemnotesTest < ApplicationSystemTestCase
  setup do
    @ordritemnote = ordritemnotes(:one)
  end

  test "visiting the index" do
    visit ordritemnotes_url
    assert_selector "h1", text: "Ordritemnotes"
  end

  test "should create ordritemnote" do
    visit ordritemnotes_url
    click_on "New ordritemnote"

    fill_in "Note", with: @ordritemnote.note
    fill_in "Ordritem", with: @ordritemnote.ordritem_id
    click_on "Create Ordritemnote"

    assert_text "Ordritemnote was successfully created"
    click_on "Back"
  end

  test "should update Ordritemnote" do
    visit ordritemnote_url(@ordritemnote)
    click_on "Edit this ordritemnote", match: :first

    fill_in "Note", with: @ordritemnote.note
    fill_in "Ordritem", with: @ordritemnote.ordritem_id
    click_on "Update Ordritemnote"

    assert_text "Ordritemnote was successfully updated"
    click_on "Back"
  end

  test "should destroy Ordritemnote" do
    visit ordritemnote_url(@ordritemnote)
    click_on "Destroy this ordritemnote", match: :first

    assert_text "Ordritemnote was successfully destroyed"
  end
end

require "test_helper"

class OrdritemnotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ordritemnote = ordritemnotes(:one)
  end

  test "should get index" do
    get ordritemnotes_url
    assert_response :success
  end

  test "should get new" do
    get new_ordritemnote_url
    assert_response :success
  end

  test "should create ordritemnote" do
    assert_difference("Ordritemnote.count") do
      post ordritemnotes_url, params: { ordritemnote: { note: @ordritemnote.note, ordritem_id: @ordritemnote.ordritem_id } }
    end

    assert_redirected_to ordritemnote_url(Ordritemnote.last)
  end

  test "should show ordritemnote" do
    get ordritemnote_url(@ordritemnote)
    assert_response :success
  end

  test "should get edit" do
    get edit_ordritemnote_url(@ordritemnote)
    assert_response :success
  end

  test "should update ordritemnote" do
    patch ordritemnote_url(@ordritemnote), params: { ordritemnote: { note: @ordritemnote.note, ordritem_id: @ordritemnote.ordritem_id } }
    assert_redirected_to ordritemnote_url(@ordritemnote)
  end

  test "should destroy ordritemnote" do
    assert_difference("Ordritemnote.count", 0) do
      delete ordritemnote_url(@ordritemnote)
    end

    assert_redirected_to ordritemnotes_url
  end
end
